import { View, Text, StyleSheet, Dimensions, ActivityIndicator, TouchableOpacity } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AudioVisualizer } from '../../components/AudioVisualizer';
import { useAudio } from '../../context/AudioContext';
import Slider from '@react-native-community/slider';
import { WebView } from 'react-native-webview';
import { Play, Pause } from 'lucide-react-native';

const { width } = Dimensions.get('window');

export default function LiveScreen() {
    const { isPlaying, isBuffering, togglePlay, volume, setVolume } = useAudio();

    return (
        <LinearGradient
            colors={Colors.background.secondary ? [Colors.background.default, Colors.background.secondary] : ['#0a0a1a', '#12122a']}
            style={styles.container}
        >
            <SafeAreaView style={styles.safeArea}>
                <View style={styles.content}>
                    <Text style={styles.headerTitle}>Harmonic Beacon</Text>
                    <Text style={styles.headerSubtitle}>Live Resonance</Text>

                    {/* Lofi Girl Video (Visuals only, audio managed separately via AudioContext) */}
                    <View style={styles.videoContainer}>
                        <WebView
                            style={styles.webView}
                            javaScriptEnabled={true}
                            domStorageEnabled={true}
                            source={{ uri: "https://www.youtube.com/embed/jfKfPfyJRdk?controls=0&showinfo=0&autoplay=1&mute=1&loop=1&playlist=jfKfPfyJRdk" }}
                            scrollEnabled={false}
                        />
                        <View style={styles.liveBadge}>
                            <View style={styles.liveDot} />
                            <Text style={styles.liveText}>LIVE</Text>
                        </View>
                    </View>

                    {/* Audio Visualizer */}
                    <View style={styles.visualizerContainer}>
                        <AudioVisualizer isPlaying={isPlaying} barCount={6} />
                    </View>

                    {/* Controls */}
                    <View style={styles.controlsContainer}>
                        <Text style={styles.controlLabel}>Beacon Volume</Text>
                        <View style={styles.sliderRow}>
                            <Text style={styles.volIcon}>🔈</Text>
                            <Slider
                                style={{ width: '100%', height: 40, flex: 1 }}
                                minimumValue={0}
                                maximumValue={1}
                                value={volume}
                                onValueChange={setVolume}
                                minimumTrackTintColor={Colors.primary[500]}
                                maximumTrackTintColor={Colors.border.subtle}
                                thumbTintColor={Colors.primary[400]}
                            />
                            <Text style={styles.volIcon}>🔊</Text>
                        </View>

                        <View style={styles.playBtnContainer}>
                            <TouchableOpacity onPress={togglePlay} style={styles.mainPlayBtn}>
                                {isPlaying ? <Pause size={24} color="white" /> : <Play size={24} color="white" style={{ marginLeft: 4 }} />}
                            </TouchableOpacity>
                            <Text style={styles.statusText}>
                                {isBuffering ? "Buffering..." : isPlaying ? "Pause Beacon Audio" : "Play Beacon Audio"}
                            </Text>
                        </View>
                    </View>

                    <View style={styles.infoCard}>
                        <Text style={styles.infoTitle}>Deep Calm Session</Text>
                        <Text style={styles.infoText}>
                            Tune into the global frequency. This live resonance helps reduce stress and improve sleep quality.
                        </Text>
                    </View>
                </View>
            </SafeAreaView>
        </LinearGradient>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    safeArea: {
        flex: 1,
    },
    content: {
        padding: 24,
        flex: 1,
    },
    headerTitle: {
        fontSize: 28,
        fontWeight: '700',
        color: Colors.text.primary,
    },
    headerSubtitle: {
        fontSize: 16,
        color: Colors.text.secondary,
        marginBottom: 32,
    },
    videoContainer: {
        width: '100%',
        height: width * 0.56, // 16:9 
        backgroundColor: '#000',
        borderRadius: 16,
        overflow: 'hidden',
        marginBottom: 24,
        borderWidth: 1,
        borderColor: Colors.border.subtle,
    },
    webView: {
        flex: 1,
        opacity: 0.8,
    },
    liveBadge: {
        position: 'absolute',
        top: 12,
        left: 12,
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: 'rgba(0,0,0,0.6)',
        paddingHorizontal: 8,
        paddingVertical: 4,
        borderRadius: 4,
        gap: 6,
    },
    liveDot: {
        width: 6,
        height: 6,
        borderRadius: 3,
        backgroundColor: '#ef4444',
    },
    liveText: {
        color: 'white',
        fontSize: 10,
        fontWeight: '700',
        letterSpacing: 0.5,
    },
    visualizerContainer: {
        height: 60,
        justifyContent: 'center',
        alignItems: 'center',
        marginBottom: 12,
    },
    controlsContainer: {
        marginBottom: 32,
    },
    controlLabel: {
        color: Colors.text.secondary,
        fontSize: 14,
        marginBottom: 8,
        fontWeight: '500',
    },
    sliderRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
    },
    volIcon: {
        fontSize: 16,
    },
    playBtnContainer: {
        alignItems: 'center',
        marginTop: 8,
        gap: 12,
    },
    mainPlayBtn: {
        width: 56,
        height: 56,
        borderRadius: 28,
        backgroundColor: Colors.primary[600],
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: Colors.primary[500],
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 10,
        elevation: 6,
    },
    statusText: {
        color: Colors.primary[300],
        fontSize: 12,
        fontWeight: '500',
    },
    infoCard: {
        backgroundColor: Colors.background.card,
        padding: 20,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: Colors.border.subtle,
    },
    infoTitle: {
        fontSize: 18,
        fontWeight: '600',
        color: Colors.text.primary,
        marginBottom: 8,
    },
    infoText: {
        fontSize: 14,
        color: Colors.text.secondary,
        lineHeight: 22,
    },
});
