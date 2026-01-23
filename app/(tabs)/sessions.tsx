import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function SessionsScreen() {
    return (
        <LinearGradient
            colors={['#0a0a1a', '#12122a']}
            style={styles.container}
        >
            <SafeAreaView style={styles.safeArea}>
                <View style={styles.content}>
                    <Text style={styles.headerTitle}>Sessions</Text>
                    <Text style={styles.headerSubtitle}>Track your wellness</Text>

                    <View style={styles.connectCard}>
                        <View style={styles.connectIcon}>
                            <Text style={{ fontSize: 20 }}>❤️</Text>
                        </View>
                        <View style={styles.connectInfo}>
                            <Text style={styles.connectTitle}>Connect Health</Text>
                            <Text style={styles.connectSubtitle}>Link Apple Health / Google Fit</Text>
                        </View>
                        <TouchableOpacity style={styles.connectBtn}>
                            <Text style={styles.connectBtnText}>Connect</Text>
                        </TouchableOpacity>
                    </View>

                    <View style={styles.emptyState}>
                        <View style={styles.orb} />
                        <Text style={styles.emptyTitle}>Start a Session</Text>
                        <Text style={styles.emptyText}>Listen to the beacon and track your heart rate variability in real-time.</Text>

                        <TouchableOpacity style={styles.startBtn}>
                            <Text style={styles.startBtnText}>Begin Solo Session</Text>
                        </TouchableOpacity>
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
    connectCard: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.background.card,
        padding: 16,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: Colors.border.subtle,
        marginBottom: 32,
        gap: 12,
    },
    connectIcon: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: 'rgba(255,255,255,0.1)',
        alignItems: 'center',
        justifyContent: 'center',
    },
    connectInfo: {
        flex: 1,
    },
    connectTitle: {
        fontSize: 14,
        fontWeight: '600',
        color: Colors.text.primary,
    },
    connectSubtitle: {
        fontSize: 12,
        color: Colors.text.muted,
    },
    connectBtn: {
        backgroundColor: 'rgba(99, 70, 255, 0.2)',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: 'rgba(99, 70, 255, 0.3)',
    },
    connectBtnText: {
        fontSize: 12,
        fontWeight: '600',
        color: '#a9a4ff',
    },
    emptyState: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        paddingBottom: 80,
    },
    orb: {
        width: 80,
        height: 80,
        borderRadius: 40,
        backgroundColor: Colors.primary[600],
        marginBottom: 24,
        opacity: 0.8,
        shadowColor: Colors.primary[500],
        shadowOffset: { width: 0, height: 0 },
        shadowOpacity: 0.5,
        shadowRadius: 30,
        elevation: 10,
    },
    emptyTitle: {
        fontSize: 20,
        fontWeight: '600',
        color: Colors.text.primary,
        marginBottom: 8,
    },
    emptyText: {
        textAlign: 'center',
        color: Colors.text.secondary,
        fontSize: 14,
        lineHeight: 20,
        marginBottom: 32,
        maxWidth: 260,
    },
    startBtn: {
        width: '100%',
        backgroundColor: Colors.primary[600],
        paddingVertical: 16,
        borderRadius: 16,
        alignItems: 'center',
        justifyContent: 'center',
    },
    startBtnText: {
        color: 'white',
        fontSize: 16,
        fontWeight: '600',
    }
});
