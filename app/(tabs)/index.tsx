import { View, Text, StyleSheet, TouchableOpacity, Animated } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AudioVisualizer } from '../../components/AudioVisualizer';
import { useAudio } from '../../context/AudioContext';
import { Play, Pause, X } from 'lucide-react-native';
import Slider from '@react-native-community/slider';
import { useEffect, useRef } from 'react';

export default function LiveScreen() {
    const {
        isPlaying,
        isBuffering,
        beaconConnected,
        beaconReconnecting,
        togglePlay,
        connectBeacon,
        disconnectBeacon,
        volume,
        setVolume,
    } = useAudio();

    // Pulsing animation for reconnecting state
    const pulseAnim = useRef(new Animated.Value(1)).current;

    useEffect(() => {
        if (beaconReconnecting) {
            const pulse = Animated.loop(
                Animated.sequence([
                    Animated.timing(pulseAnim, {
                        toValue: 0.3,
                        duration: 800,
                        useNativeDriver: true,
                    }),
                    Animated.timing(pulseAnim, {
                        toValue: 1,
                        duration: 800,
                        useNativeDriver: true,
                    }),
                ])
            );
            pulse.start();
            return () => pulse.stop();
        } else {
            pulseAnim.setValue(1);
        }
    }, [beaconReconnecting, pulseAnim]);

    // Handle the main button press
    const handleMainButton = async () => {
        if (!beaconConnected && !isBuffering) {
            await connectBeacon();
        } else if (beaconConnected) {
            await togglePlay();
        }
    };

    // Determine status text
    const getStatusText = () => {
        if (isBuffering) return 'Connecting to Beacon...';
        if (beaconReconnecting) return 'Reconnecting...';
        if (beaconConnected && isPlaying) return 'Live Resonance Active';
        if (beaconConnected && !isPlaying) return 'Beacon Paused';
        return 'Tap to Connect';
    };

    // Determine badge style based on connection state
    const getBadgeStyle = () => {
        if (beaconReconnecting) {
            return {
                badgeBg: 'rgba(245, 158, 11, 0.2)',
                badgeBorder: 'rgba(245, 158, 11, 0.4)',
                dotColor: '#f59e0b',
                textColor: '#f59e0b',
            };
        }
        if (beaconConnected) {
            return {
                badgeBg: 'rgba(239, 68, 68, 0.2)',
                badgeBorder: 'rgba(239, 68, 68, 0.4)',
                dotColor: '#ef4444',
                textColor: '#ef4444',
            };
        }
        return {
            badgeBg: 'rgba(255, 255, 255, 0.1)',
            badgeBorder: 'rgba(255, 255, 255, 0.2)',
            dotColor: 'rgba(255, 255, 255, 0.4)',
            textColor: 'rgba(255, 255, 255, 0.4)',
        };
    };

    const badge = getBadgeStyle();

    return (
        <View style={styles.container}>
            {/* Gradient background */}
            <LinearGradient
                colors={['#12122a', '#0a0a1a', '#0d0d20']}
                style={StyleSheet.absoluteFill}
            />

            {/* Content */}
            <SafeAreaView style={styles.safeArea}>
                <View style={styles.content}>
                    {/* Header */}
                    <View style={styles.header}>
                        <View style={[
                            styles.liveBadge,
                            {
                                backgroundColor: badge.badgeBg,
                                borderColor: badge.badgeBorder,
                            }
                        ]}>
                            <Animated.View
                                style={[
                                    styles.liveDot,
                                    {
                                        backgroundColor: badge.dotColor,
                                        opacity: beaconReconnecting ? pulseAnim : 1,
                                    },
                                ]}
                            />
                            <Text style={[styles.liveText, { color: badge.textColor }]}>
                                {beaconConnected ? 'LIVE' : beaconReconnecting ? 'RECONNECTING' : 'OFFLINE'}
                            </Text>
                        </View>
                        <Text style={[styles.headerTitle, { marginTop: 10 }]}>Harmonic Beacon</Text>
                    </View>

                    {/* Spacer to push controls down */}
                    <View style={{ flex: 1 }} />

                    {/* Audio Visualizer */}
                    <View style={styles.visualizerContainer}>
                        <AudioVisualizer isPlaying={isPlaying && beaconConnected} barCount={8} />
                    </View>

                    {/* Play Button */}
                    <View style={styles.playBtnContainer}>
                        <TouchableOpacity onPress={handleMainButton} style={styles.mainPlayBtn}>
                            {isPlaying && beaconConnected ? (
                                <Pause size={32} color="white" />
                            ) : (
                                <Play size={32} color="white" style={{ marginLeft: 4 }} />
                            )}
                        </TouchableOpacity>
                        <Text style={[styles.statusDetailText, { marginTop: 20 }]}>
                            {getStatusText()}
                        </Text>
                    </View>

                    {/* Volume slider when connected */}
                    {beaconConnected && (
                        <View style={styles.volumeContainer}>
                            <Text style={styles.volumeLabel}>Volume</Text>
                            <View style={styles.volumeRow}>
                                <Text style={styles.volumeIcon}>-</Text>
                                <Slider
                                    style={{ flex: 1, height: 40 }}
                                    minimumValue={0}
                                    maximumValue={1}
                                    value={volume}
                                    onValueChange={setVolume}
                                    minimumTrackTintColor={Colors.primary[500]}
                                    maximumTrackTintColor="rgba(255,255,255,0.15)"
                                    thumbTintColor="#ffffff"
                                />
                                <Text style={styles.volumeIcon}>+</Text>
                            </View>
                            <Text style={styles.volumePercent}>
                                {Math.round(volume * 100)}%
                            </Text>
                        </View>
                    )}

                    {/* Disconnect button */}
                    {beaconConnected && (
                        <View style={styles.disconnectContainer}>
                            <TouchableOpacity
                                onPress={disconnectBeacon}
                                style={styles.disconnectBtn}
                            >
                                <X size={16} color="rgba(255,255,255,0.6)" />
                                <Text style={styles.disconnectText}>Disconnect</Text>
                            </TouchableOpacity>
                        </View>
                    )}

                    {/* Status Text */}
                    <View style={styles.statusContainer}>
                        <Text style={styles.statusDetailText}>
                            {beaconConnected && !beaconReconnecting
                                ? 'WebRTC connected to beacon room'
                                : ''}
                        </Text>
                    </View>
                </View>
            </SafeAreaView>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#0a0a1a',
    },
    safeArea: {
        flex: 1,
    },
    content: {
        flex: 1,
        padding: 24,
    },
    header: {
        alignItems: 'center',
        paddingTop: 20,
    },
    liveBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 20,
        gap: 6,
        marginBottom: 16,
        borderWidth: 1,
    },
    liveDot: {
        width: 8,
        height: 8,
        borderRadius: 4,
    },
    liveText: {
        fontSize: 12,
        fontWeight: '700',
        letterSpacing: 1,
    },
    headerTitle: {
        fontSize: 36,
        fontWeight: '700',
        color: Colors.text.primary,
        textAlign: 'center',
        textShadowColor: 'rgba(0,0,0,0.5)',
        textShadowOffset: { width: 0, height: 2 },
        textShadowRadius: 10,
    },
    visualizerContainer: {
        height: 80,
        justifyContent: 'center',
        alignItems: 'center',
        marginBottom: 24,
    },
    playBtnContainer: {
        alignItems: 'center',
        marginBottom: 24,
    },
    mainPlayBtn: {
        width: 80,
        height: 80,
        borderRadius: 40,
        backgroundColor: 'rgba(99, 70, 255, 0.8)',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: Colors.primary[500],
        shadowOffset: { width: 0, height: 0 },
        shadowOpacity: 0.6,
        shadowRadius: 20,
        elevation: 10,
        borderWidth: 2,
        borderColor: 'rgba(255,255,255,0.2)',
    },
    volumeContainer: {
        alignItems: 'center',
        paddingHorizontal: 24,
        marginBottom: 16,
    },
    volumeLabel: {
        fontSize: 12,
        color: Colors.text.muted,
        marginBottom: 4,
    },
    volumeRow: {
        flexDirection: 'row',
        alignItems: 'center',
        width: '100%',
        gap: 8,
    },
    volumeIcon: {
        fontSize: 16,
        color: Colors.text.muted,
        fontWeight: '600',
    },
    volumePercent: {
        fontSize: 12,
        color: Colors.text.muted,
        marginTop: 2,
    },
    disconnectContainer: {
        alignItems: 'center',
        marginBottom: 16,
    },
    disconnectBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        paddingHorizontal: 16,
        paddingVertical: 8,
        borderRadius: 20,
        backgroundColor: 'rgba(255,255,255,0.06)',
        borderWidth: 1,
        borderColor: 'rgba(255,255,255,0.1)',
    },
    disconnectText: {
        fontSize: 13,
        color: 'rgba(255,255,255,0.6)',
    },
    statusContainer: {
        marginTop: 'auto',
        paddingBottom: 20,
        alignItems: 'center',
    },
    statusDetailText: {
        fontSize: 13,
        color: Colors.text.muted,
        textAlign: 'center',
        fontStyle: 'italic',
    },
});
