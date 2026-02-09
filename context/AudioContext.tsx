import React, { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react';
import { Audio, InterruptionModeIOS, InterruptionModeAndroid } from 'expo-av';
import { registerGlobals } from '@livekit/react-native';
import {
    Room,
    RoomEvent,
    Track,
    RemoteTrack,
    RemoteAudioTrack,
    RemoteParticipant,
    RemoteTrackPublication,
    ConnectionState,
} from 'livekit-client';

// Register LiveKit globals (WebRTC polyfills for React Native)
registerGlobals();

// --- Configuration ---
const LIVEKIT_URL = process.env.EXPO_PUBLIC_LIVEKIT_URL || 'wss://live.altermundi.net';
const LIVEKIT_TOKEN = process.env.EXPO_PUBLIC_LIVEKIT_TOKEN || '';
const BEACON_PUBLISHER_IDENTITY = 'beacon01';

type AudioContextType = {
    // Beacon (LiveKit)
    isPlaying: boolean;
    isBuffering: boolean;
    beaconConnected: boolean;
    beaconReconnecting: boolean;
    volume: number;
    togglePlay: () => Promise<void>;
    setVolume: (v: number) => Promise<void>;
    connectBeacon: () => Promise<void>;
    disconnectBeacon: () => Promise<void>;
    // Meditation (expo-av -- unchanged)
    loadMeditation: (source: any) => Promise<void>;
    unloadMeditation: () => Promise<void>;
    meditationSound: Audio.Sound | null;
    meditationIsPlaying: boolean;
    meditationVolume: number;
    setMeditationVolume: (v: number) => Promise<void>;
    toggleMeditation: () => Promise<void>;
    seekMeditation: (millis: number) => Promise<void>;
    meditationDuration: number;
    meditationPosition: number;
};

const AudioContext = createContext<AudioContextType>({
    isPlaying: false,
    isBuffering: false,
    beaconConnected: false,
    beaconReconnecting: false,
    volume: 0.5,
    togglePlay: async () => { },
    setVolume: async () => { },
    connectBeacon: async () => { },
    disconnectBeacon: async () => { },
    loadMeditation: async () => { },
    unloadMeditation: async () => { },
    meditationSound: null,
    meditationIsPlaying: false,
    meditationVolume: 1.0,
    meditationDuration: 0,
    meditationPosition: 0,
    setMeditationVolume: async () => { },
    toggleMeditation: async () => { },
    seekMeditation: async () => { },
});

export function useAudio() {
    return useContext(AudioContext);
}

export function AudioProvider({ children }: { children: React.ReactNode }) {
    // --- LiveKit Beacon State ---
    const roomRef = useRef<Room | null>(null);
    const beaconTrackRef = useRef<RemoteAudioTrack | null>(null);
    const [isPlaying, setIsPlaying] = useState(false);
    const [isBuffering, setIsBuffering] = useState(false);
    const [beaconConnected, setBeaconConnected] = useState(false);
    const [beaconReconnecting, setBeaconReconnecting] = useState(false);
    const [volume, setVolumeState] = useState(0.5);

    // --- Meditation State (unchanged from original) ---
    const [meditationSound, setMeditationSound] = useState<Audio.Sound | null>(null);
    const [meditationIsPlaying, setMeditationIsPlaying] = useState(false);
    const [meditationDuration, setMeditationDuration] = useState(0);
    const [meditationPosition, setMeditationPosition] = useState(0);
    const [meditationVolume, setMeditationVolumeState] = useState(1.0);

    // --- Audio Session Setup ---
    const configureAudioSession = useCallback(async () => {
        try {
            await Audio.setAudioModeAsync({
                playsInSilentModeIOS: true,
                staysActiveInBackground: true,
                interruptionModeIOS: InterruptionModeIOS.MixWithOthers,
                interruptionModeAndroid: InterruptionModeAndroid.DuckOthers,
                shouldDuckAndroid: false, // We control volumes ourselves via crossfader
                playThroughEarpieceAndroid: false,
            });
        } catch (error) {
            console.error('[AudioContext] Failed to configure audio session:', error);
        }
    }, []);

    // Initialize audio session on mount
    useEffect(() => {
        configureAudioSession();
        return () => {
            // Cleanup on unmount
            if (roomRef.current) {
                roomRef.current.disconnect();
                roomRef.current = null;
            }
        };
    }, [configureAudioSession]);

    // --- Beacon Volume Control ---
    // KEY POC FINDING: RemoteAudioTrack volume control in React Native.
    // The livekit-client RemoteAudioTrack may or may not expose a setVolume() method
    // depending on the version and platform. We try it first, and fall back to
    // enable/disable (mute/unmute) for the volume=0 case.
    const applyBeaconVolume = useCallback((vol: number) => {
        const track = beaconTrackRef.current;
        if (!track) return;

        try {
            // Attempt 1: Use setVolume() if available (some livekit-client versions expose this)
            if (typeof (track as any).setVolume === 'function') {
                (track as any).setVolume(vol);
                console.log(`[AudioContext] Beacon volume set via setVolume(${vol})`);
                return;
            }
        } catch (e) {
            console.warn('[AudioContext] setVolume() failed:', e);
        }

        try {
            // Attempt 2: Access the underlying MediaStreamTrack and try to adjust
            // via the Web Audio API or RTCRtpReceiver. This is platform-dependent.
            const mediaStreamTrack = track.mediaStreamTrack;
            if (mediaStreamTrack) {
                // On React Native, we can at least mute/unmute
                if (vol === 0) {
                    mediaStreamTrack.enabled = false;
                    console.log('[AudioContext] Beacon muted via mediaStreamTrack.enabled = false');
                } else {
                    mediaStreamTrack.enabled = true;
                    console.log(`[AudioContext] Beacon unmuted, requested vol=${vol} (no granular control)`);
                }
            }
        } catch (e) {
            console.warn('[AudioContext] MediaStreamTrack volume fallback failed:', e);
        }
    }, []);

    // --- LiveKit Room Connection ---
    const connectBeacon = useCallback(async () => {
        if (roomRef.current?.state === ConnectionState.Connected) {
            console.log('[AudioContext] Already connected to beacon room');
            return;
        }

        if (!LIVEKIT_TOKEN) {
            console.error('[AudioContext] No LIVEKIT_TOKEN configured. Set EXPO_PUBLIC_LIVEKIT_TOKEN in .env');
            return;
        }

        setIsBuffering(true);

        try {
            const room = new Room({
                adaptiveStream: true,
                dynacast: false, // We are a listener only
            });

            // --- Event Listeners ---

            room.on(RoomEvent.Connected, () => {
                console.log('[AudioContext] Connected to beacon room');
                setBeaconConnected(true);
                setBeaconReconnecting(false);
                setIsBuffering(false);
                setIsPlaying(true);

                // Re-apply audio session config after LiveKit connects
                // (LiveKit may reconfigure the audio session during connection)
                configureAudioSession();
            });

            room.on(RoomEvent.Disconnected, () => {
                console.log('[AudioContext] Disconnected from beacon room');
                setBeaconConnected(false);
                setBeaconReconnecting(false);
                setIsPlaying(false);
                setIsBuffering(false);
                beaconTrackRef.current = null;
            });

            room.on(RoomEvent.Reconnecting, () => {
                console.log('[AudioContext] Reconnecting to beacon room...');
                setBeaconReconnecting(true);
            });

            room.on(RoomEvent.Reconnected, () => {
                console.log('[AudioContext] Reconnected to beacon room');
                setBeaconReconnecting(false);
                // Re-apply audio session config after reconnection
                configureAudioSession();
            });

            room.on(
                RoomEvent.TrackSubscribed,
                (
                    track: RemoteTrack,
                    publication: RemoteTrackPublication,
                    participant: RemoteParticipant,
                ) => {
                    console.log(
                        `[AudioContext] Track subscribed: ${track.kind} from ${participant.identity}`
                    );

                    if (track.kind === Track.Kind.Audio) {
                        const audioTrack = track as RemoteAudioTrack;
                        beaconTrackRef.current = audioTrack;

                        // Apply current volume setting to the newly subscribed track
                        applyBeaconVolume(volume);

                        console.log('[AudioContext] Beacon audio track attached');
                    }
                },
            );

            room.on(
                RoomEvent.TrackUnsubscribed,
                (
                    track: RemoteTrack,
                    publication: RemoteTrackPublication,
                    participant: RemoteParticipant,
                ) => {
                    if (track.kind === Track.Kind.Audio) {
                        console.log(
                            `[AudioContext] Audio track unsubscribed from ${participant.identity}`
                        );
                        if (beaconTrackRef.current === track) {
                            beaconTrackRef.current = null;
                        }
                    }
                },
            );

            // Connect to the room
            await room.connect(LIVEKIT_URL, LIVEKIT_TOKEN);
            roomRef.current = room;

            // Check if the beacon publisher is already in the room and has tracks
            room.remoteParticipants.forEach((participant) => {
                participant.audioTrackPublications.forEach((pub) => {
                    if (pub.track && pub.track.kind === Track.Kind.Audio) {
                        const audioTrack = pub.track as RemoteAudioTrack;
                        beaconTrackRef.current = audioTrack;
                        applyBeaconVolume(volume);
                        console.log(
                            `[AudioContext] Found existing beacon track from ${participant.identity}`
                        );
                    }
                });
            });
        } catch (error) {
            console.error('[AudioContext] Failed to connect to beacon room:', error);
            setIsBuffering(false);
            setBeaconConnected(false);
        }
    }, [volume, configureAudioSession, applyBeaconVolume]);

    const disconnectBeacon = useCallback(async () => {
        if (roomRef.current) {
            roomRef.current.disconnect();
            roomRef.current = null;
        }
        beaconTrackRef.current = null;
        setBeaconConnected(false);
        setBeaconReconnecting(false);
        setIsPlaying(false);
        setIsBuffering(false);
    }, []);

    // --- Beacon Playback Toggle ---
    // When connected, toggle mutes/unmutes the beacon track.
    // When disconnected, this is a no-op (use connectBeacon instead).
    const togglePlay = useCallback(async () => {
        if (!roomRef.current || roomRef.current.state !== ConnectionState.Connected) {
            return;
        }

        if (isPlaying) {
            // Mute beacon
            applyBeaconVolume(0);
            setIsPlaying(false);
        } else {
            // Unmute beacon at current volume
            applyBeaconVolume(volume);
            setIsPlaying(true);
        }
    }, [isPlaying, volume, applyBeaconVolume]);

    // --- Beacon Volume ---
    const setVolume = useCallback(async (v: number) => {
        setVolumeState(v);
        if (isPlaying) {
            applyBeaconVolume(v);
        }
    }, [isPlaying, applyBeaconVolume]);

    // --- Meditation Logic (unchanged from original) ---

    const loadMeditation = useCallback(async (source: any) => {
        // Unload existing if any
        if (meditationSound) {
            await meditationSound.unloadAsync();
        }

        try {
            const { sound: newMeditation } = await Audio.Sound.createAsync(
                source,
                { shouldPlay: true, volume: meditationVolume },
                (status: any) => {
                    if (status.isLoaded) {
                        setMeditationIsPlaying(status.isPlaying);
                        setMeditationDuration(status.durationMillis || 0);
                        setMeditationPosition(status.positionMillis || 0);
                        if (status.didJustFinish) {
                            setMeditationIsPlaying(false);
                            setMeditationPosition(0);
                        }
                    }
                }
            );
            setMeditationSound(newMeditation);
        } catch (error) {
            console.error('[AudioContext] Error loading meditation:', error);
        }
    }, [meditationSound, meditationVolume]);

    const unloadMeditation = useCallback(async () => {
        if (meditationSound) {
            setMeditationIsPlaying(false);
            setMeditationPosition(0);
            setMeditationDuration(0);
            await meditationSound.stopAsync();
            await meditationSound.unloadAsync();
            setMeditationSound(null);
        }
    }, [meditationSound]);

    const toggleMeditation = useCallback(async () => {
        if (!meditationSound) return;
        if (meditationIsPlaying) {
            await meditationSound.pauseAsync();
        } else {
            await meditationSound.playAsync();
        }
    }, [meditationSound, meditationIsPlaying]);

    const seekMeditation = useCallback(async (millis: number) => {
        if (meditationSound) {
            await meditationSound.setPositionAsync(millis);
        }
    }, [meditationSound]);

    const setMeditationVolume = useCallback(async (v: number) => {
        setMeditationVolumeState(v);
        if (meditationSound) {
            await meditationSound.setVolumeAsync(v);
        }
    }, [meditationSound]);

    return (
        <AudioContext.Provider
            value={{
                isPlaying,
                isBuffering,
                beaconConnected,
                beaconReconnecting,
                volume,
                togglePlay,
                setVolume,
                connectBeacon,
                disconnectBeacon,
                loadMeditation,
                unloadMeditation,
                meditationSound,
                meditationIsPlaying,
                meditationVolume,
                setMeditationVolume,
                toggleMeditation,
                seekMeditation,
                meditationDuration,
                meditationPosition,
            }}
        >
            {children}
        </AudioContext.Provider>
    );
}
