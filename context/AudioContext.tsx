import React, { createContext, useContext, useState, useEffect, useRef } from 'react';
import { Audio } from 'expo-av';

type AudioContextType = {
    isPlaying: boolean;
    isBuffering: boolean;
    volume: number;
    togglePlay: () => Promise<void>;
    setVolume: (v: number) => Promise<void>;
    // Play a specific local file (for meditations)
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
    volume: 0.5,
    togglePlay: async () => { },
    setVolume: async () => { },
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
    const [sound, setSound] = useState<Audio.Sound | null>(null);
    const [isPlaying, setIsPlaying] = useState(false);
    const [isBuffering, setIsBuffering] = useState(false);
    const [volume, setVolumeState] = useState(0.5);

    const [meditationSound, setMeditationSound] = useState<Audio.Sound | null>(null);
    const [meditationIsPlaying, setMeditationIsPlaying] = useState(false);
    const [meditationDuration, setMeditationDuration] = useState(0);
    const [meditationPosition, setMeditationPosition] = useState(0);
    const [meditationVolume, setMeditationVolumeState] = useState(1.0);

    // Live stream URL (Lofi placeholder)
    const LIVE_STREAM_URL = "https://streams.ilovemusic.de/iloveradio17.mp3";

    // Initialize Audio Session
    useEffect(() => {
        async function initAudio() {
            try {
                await Audio.setAudioModeAsync({
                    playsInSilentModeIOS: true,
                    staysActiveInBackground: true,
                    shouldDuckAndroid: true,
                });
                loadSound();
            } catch (error) {
                console.error("Failed to init audio:", error);
            }
        }
        initAudio();

        return () => {
            if (sound) {
                sound.unloadAsync();
            }
            if (meditationSound) {
                meditationSound.unloadAsync();
            }
        };
    }, []);

    const loadSound = async () => {
        try {
            const { sound: newSound } = await Audio.Sound.createAsync(
                { uri: LIVE_STREAM_URL },
                { shouldPlay: false, volume: volume },
                onPlaybackStatusUpdate
            );
            setSound(newSound);
        } catch (error) {
            console.error("Error loading sound:", error);
        }
    };

    const onPlaybackStatusUpdate = (status: any) => {
        if (status.isLoaded) {
            setIsPlaying(status.isPlaying);
            setIsBuffering(status.isBuffering);
        }
    };

    const togglePlay = async () => {
        if (!sound) return;
        if (isPlaying) {
            await sound.pauseAsync();
        } else {
            await sound.playAsync();
        }
    };

    const setVolume = async (v: number) => {
        setVolumeState(v);
        if (sound) {
            await sound.setVolumeAsync(v);
        }
    };

    // --- Meditation Logic ---

    const loadMeditation = async (source: any) => {
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

            // Ensure live stream is playing in background
            if (sound && !isPlaying) {
                await sound.playAsync();
            }
        } catch (error) {
            console.error("Error loading meditation:", error);
        }
    };

    const unloadMeditation = async () => {
        if (meditationSound) {
            setMeditationIsPlaying(false);
            setMeditationPosition(0);
            setMeditationDuration(0);
            await meditationSound.stopAsync();
            await meditationSound.unloadAsync();
            setMeditationSound(null);
        }
    };

    const toggleMeditation = async () => {
        if (!meditationSound) return;
        if (meditationIsPlaying) {
            await meditationSound.pauseAsync();
        } else {
            await meditationSound.playAsync();
        }
    };

    const seekMeditation = async (millis: number) => {
        if (meditationSound) {
            await meditationSound.setPositionAsync(millis);
        }
    };

    const setMeditationVolume = async (v: number) => {
        setMeditationVolumeState(v);
        if (meditationSound) {
            await meditationSound.setVolumeAsync(v);
        }
    };

    return (
        <AudioContext.Provider
            value={{
                isPlaying,
                isBuffering,
                volume,
                togglePlay,
                setVolume,
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
