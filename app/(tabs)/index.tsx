import { View, Text, StyleSheet, Dimensions, TouchableOpacity } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AudioVisualizer } from '../../components/AudioVisualizer';
import { useAudio } from '../../context/AudioContext';
import Slider from '@react-native-community/slider';
import { useVideoPlayer, VideoView } from 'expo-video';
import { Play, Pause } from 'lucide-react-native';
import { BlurView } from 'expo-blur';
import { useEffect } from 'react';

const { width, height } = Dimensions.get('window');

// Local ambient video - place your beacon footage in assets/video/
// Name your file: beacon_ambient.mp4
const AMBIENT_VIDEO = require('../../assets/video/beacon_ambient.mp4');

export default function LiveScreen() {
    const { isPlaying, isBuffering, togglePlay, volume, setVolume } = useAudio();

    // Create video player with expo-video
    const player = useVideoPlayer(AMBIENT_VIDEO, player => {
        player.loop = true;
        player.muted = true;
        player.play();
    });

    return (
        <View style={styles.container}>
            {/* Full-screen background video */}
            <VideoView
                player={player}
                style={styles.backgroundVideo}
                contentFit="cover"
                nativeControls={false}
            />

            {/* Gradient overlay for readability */}
            <LinearGradient
                colors={['rgba(10, 10, 26, 0.3)', 'rgba(10, 10, 26, 0.7)', 'rgba(10, 10, 26, 0.95)']}
                style={styles.gradientOverlay}
            />

            {/* Content */}
            <SafeAreaView style={styles.safeArea}>
                <View style={styles.content}>
                    {/* Header */}
                    <View style={styles.header}>
                        <View style={styles.liveBadge}>
                            <View style={styles.liveDot} />
                            <Text style={styles.liveText}>LIVE</Text>
                        </View>
                        <Text style={[styles.headerTitle, { marginTop: 10 }]}>Harmonic Beacon</Text>
                        {/* <Text style={styles.headerSubtitle}>Tune into the global frequency</Text> */}
                    </View>

                    {/* Spacer to push controls down */}
                    <View style={{ flex: 1 }} />

                    {/* Audio Visualizer */}
                    <View style={styles.visualizerContainer}>
                        <AudioVisualizer isPlaying={isPlaying} barCount={8} />
                    </View>

                    {/* Play Button */}
                    <View style={styles.playBtnContainer}>
                        <TouchableOpacity onPress={togglePlay} style={styles.mainPlayBtn}>
                            {isPlaying ? (
                                <Pause size={32} color="white" />
                            ) : (
                                <Play size={32} color="white" style={{ marginLeft: 4 }} />
                            )}
                        </TouchableOpacity>
                        <Text style={[styles.statusDetailText, { marginTop: 20 }]}>
                            {isBuffering ? "Connecting to Beacon..." : isPlaying ? "Live Resonance Active" : "Tap to Connect"}
                        </Text>
                    </View>

                    {/* Status Text (Moved from inside removed card) */}
                    <View style={styles.statusContainer}>
                        <Text style={styles.statusDetailText}>
                            {/* 🌍 Deep Calm Session • Reduces stress & improves sleep */}
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
    backgroundVideo: {
        position: 'absolute',
        top: 0,
        left: 0,
        width: width,
        height: height,
    },
    gradientOverlay: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
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
        backgroundColor: 'rgba(239, 68, 68, 0.2)',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 20,
        gap: 6,
        marginBottom: 16,
        borderWidth: 1,
        borderColor: 'rgba(239, 68, 68, 0.4)',
    },
    liveDot: {
        width: 8,
        height: 8,
        borderRadius: 4,
        backgroundColor: '#ef4444',
    },
    liveText: {
        color: '#ef4444',
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
    headerSubtitle: {
        fontSize: 16,
        color: Colors.text.secondary,
        textAlign: 'center',
        marginTop: 8,
    },
    visualizerContainer: {
        height: 80,
        justifyContent: 'center',
        alignItems: 'center',
        marginBottom: 24,
    },
    playBtnContainer: {
        alignItems: 'center',
        marginBottom: 32,
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
    statusText: {
        color: Colors.text.secondary,
        fontSize: 14,
        fontWeight: '500',
        marginTop: 16,
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
