import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Play, Pause, X } from 'lucide-react-native';
import { useAudio } from '../../context/AudioContext';
import Slider from '@react-native-community/slider';
import { BlurView } from 'expo-blur';
import { useState } from 'react';

// Require assets to get resource IDs for Expo AV
const AudioAssets = {
    '1': require('../../assets/audio/meditations/la_mosca.m4a'),
    '2': require('../../assets/audio/meditations/humanosfera.m4a'),
    '3': require('../../assets/audio/meditations/amor.m4a'),
};

const meditations = [
    { id: '1', title: "La Mosca", duration: "0:52", color: ['#4c1d95', '#2563eb'] },
    { id: '2', title: "Humanosfera", duration: "2:03", color: ['#4338ca', '#6b21a8'] },
    { id: '3', title: "El Amor", duration: "4:35", color: ['#e11d48', '#db2777'] }
];

export default function MeditateScreen() {
    const {
        loadMeditation,
        unloadMeditation,
        toggleMeditation,
        meditationIsPlaying,
        meditationVolume,
        setMeditationVolume,
        meditationPosition,
        meditationDuration,
        seekMeditation,
        meditationSound,
        volume: beaconVolume,
        setVolume: setBeaconVolume
    } = useAudio();

    const [activeMeditation, setActiveMeditation] = useState<any>(null);
    const [mixValue, setMixValue] = useState(0.5); // 0 = beacon only, 0.5 = equal, 1 = meditation only

    // Handle mix slider changes - converts single slider to two volumes
    const handleMixChange = (value: number) => {
        setMixValue(value);
        // Center (0.5) = Meditation at 1.0, Beacon slightly lower (0.85) to favor meditation
        // Left (0) = beacon full, meditation silent
        // Right (1) = meditation full, beacon silent
        if (value <= 0.5) {
            // 0 -> Beacon 1.0, Med 0.0
            // 0.5 -> Beacon 0.85, Med 1.0
            const beaconVol = 1.0 - (value * 0.3); // 0 -> 1.0, 0.5 -> 0.85
            const medVol = value * 2; // 0 -> 0, 0.5 -> 1.0
            setBeaconVolume(beaconVol);
            setMeditationVolume(medVol);
        } else {
            // 0.5 -> Med 1.0, Beacon 0.85
            // 1.0 -> Med 1.0, Beacon 0.0
            const beaconVol = (1 - value) * 1.7; // 0.5 -> 0.85, 1.0 -> 0
            setMeditationVolume(1.0);
            setBeaconVolume(beaconVol);
        }
    };

    const startMeditation = async (item: any) => {
        if (activeMeditation?.id === item.id) {
            toggleMeditation();
        } else {
            setActiveMeditation(item);
            // @ts-ignore
            await loadMeditation(AudioAssets[item.id]);
        }
    };

    const stopSession = async () => {
        await unloadMeditation();
        setActiveMeditation(null);
    };

    return (
        <LinearGradient
            colors={['#0a0a1a', '#12122a']}
            style={styles.container}
        >
            <SafeAreaView style={styles.safeArea}>
                <ScrollView contentContainerStyle={styles.content}>
                    <Text style={styles.headerTitle}>Meditation</Text>
                    <Text style={styles.headerSubtitle}>Audio Overlays</Text>

                    {/* Cards */}
                    <View style={[styles.cardList, activeMeditation ? { paddingBottom: 220 } : {}]}>
                        {meditations.map((item, i) => (
                            <TouchableOpacity key={i} style={styles.card} onPress={() => startMeditation(item)}>
                                <LinearGradient
                                    colors={item.color as any}
                                    style={styles.cardImage}
                                    start={{ x: 0, y: 0 }}
                                    end={{ x: 1, y: 1 }}
                                >
                                    {activeMeditation?.id === item.id && meditationIsPlaying ? (
                                        <Pause size={24} color="rgba(255,255,255,0.8)" fill="rgba(255,255,255,0.8)" />
                                    ) : (
                                        <Play size={24} color="rgba(255,255,255,0.8)" fill="rgba(255,255,255,0.8)" />
                                    )}
                                </LinearGradient>
                                <View style={styles.cardInfo}>
                                    <Text style={styles.cardTitle}>{item.title}</Text>
                                    <Text style={styles.cardSubtitle}>Short Story • {item.duration}</Text>
                                </View>
                            </TouchableOpacity>
                        ))}
                    </View>
                </ScrollView>

                {/* Player Overlay */}
                {activeMeditation && (
                    <BlurView intensity={95} tint="dark" style={styles.playerOverlay}>
                        <View style={styles.playerHeader}>
                            <View>
                                <Text style={styles.playerTitle}>{activeMeditation.title}</Text>
                                <Text style={styles.playerSubtitle}>Playing with Live Beacon</Text>
                            </View>
                            <TouchableOpacity onPress={stopSession} style={styles.closeBtn}>
                                <X color="white" size={24} />
                            </TouchableOpacity>
                        </View>

                        {/* Progress Bar */}
                        <View style={styles.progressContainer}>
                            <Slider
                                style={{ width: '100%', height: 40 }}
                                minimumValue={0}
                                maximumValue={meditationDuration || 1}
                                value={meditationPosition}
                                onSlidingComplete={seekMeditation}
                                minimumTrackTintColor="white"
                                maximumTrackTintColor="rgba(255,255,255,0.3)"
                                thumbTintColor="white"
                            />
                            <View style={styles.timeRow}>
                                <Text style={styles.timeText}>
                                    {new Date(meditationPosition).toISOString().substr(14, 5)}
                                </Text>
                                <Text style={styles.timeText}>
                                    {meditationDuration ? new Date(meditationDuration).toISOString().substr(14, 5) : "00:00"}
                                </Text>
                            </View>
                        </View>

                        {/* Controls */}
                        <View style={styles.controls}>
                            <TouchableOpacity onPress={toggleMeditation} style={styles.mainPlayBtn}>
                                {meditationIsPlaying ? (
                                    <Pause size={32} color="black" fill="black" />
                                ) : (
                                    <Play size={32} color="black" fill="black" style={{ marginLeft: 4 }} />
                                )}
                            </TouchableOpacity>
                        </View>

                        {/* Mix Slider */}
                        <View style={styles.sliders}>
                            <Text style={styles.sliderLabel}>Audio Mix</Text>
                            <View style={styles.mixSliderContainer}>
                                <Text style={styles.mixLabel}>🎸 Beacon</Text>
                                <Slider
                                    style={{ flex: 1, height: 40 }}
                                    minimumValue={0}
                                    maximumValue={1}
                                    value={mixValue}
                                    onValueChange={handleMixChange}
                                    minimumTrackTintColor={Colors.primary[500]}
                                    maximumTrackTintColor={Colors.accent[400]}
                                    thumbTintColor="#ffffff"
                                />
                                <Text style={styles.mixLabel}>🧘 Voice</Text>
                            </View>
                        </View>
                    </BlurView>
                )}
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
        paddingBottom: 100,
    },
    headerTitle: {
        fontSize: 28,
        fontWeight: '700',
        color: Colors.text.primary,
    },
    headerSubtitle: {
        fontSize: 16,
        color: Colors.text.secondary,
        marginBottom: 24,
    },
    cardList: {
        gap: 16,
    },
    card: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.background.card,
        padding: 12,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: Colors.border.subtle,
        gap: 16,
    },
    cardImage: {
        width: 64,
        height: 64,
        borderRadius: 12,
        alignItems: 'center',
        justifyContent: 'center',
    },
    cardInfo: {
        flex: 1,
    },
    cardTitle: {
        fontSize: 16,
        fontWeight: '600',
        color: Colors.text.primary,
        marginBottom: 4,
    },
    cardSubtitle: {
        fontSize: 12,
        color: Colors.text.muted,
    },

    // Player
    playerOverlay: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        minHeight: 380,
        borderTopLeftRadius: 32,
        borderTopRightRadius: 32,
        padding: 24,
        paddingBottom: 100,
        overflow: 'hidden',
        borderTopWidth: 1,
        borderColor: 'rgba(255,255,255,0.1)',
    },
    playerHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        marginBottom: 24,
    },
    playerTitle: {
        fontSize: 24,
        fontWeight: '700',
        color: 'white',
    },
    playerSubtitle: {
        fontSize: 14,
        color: Colors.primary[300],
        marginTop: 4,
    },
    closeBtn: {
        padding: 4,
    },
    controls: {
        alignItems: 'center',
        marginBottom: 32,
    },
    mainPlayBtn: {
        width: 72,
        height: 72,
        borderRadius: 36,
        backgroundColor: 'white',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: 'white',
        shadowOpacity: 0.2,
        shadowRadius: 10,
        elevation: 5,
    },
    sliders: {
        gap: 16,
    },
    sliderLabel: {
        fontSize: 12,
        color: Colors.text.muted,
        marginLeft: 4,
        marginBottom: 4,
        textAlign: 'center',
    },
    mixSliderContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        width: '100%',
    },
    mixLabel: {
        fontSize: 12,
        color: Colors.text.secondary,
    },
    progressContainer: {
        marginBottom: 24,
    },
    timeRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingHorizontal: 16,
        marginTop: -8,
    },
    timeText: {
        color: 'rgba(255,255,255,0.6)',
        fontSize: 12,
        fontVariant: ['tabular-nums'],
    }
});
