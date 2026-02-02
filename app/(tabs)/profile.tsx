import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../context/AuthContext';
import { User as UserIcon, LogOut, Settings, Award } from 'lucide-react-native';

export default function ProfileScreen() {
    const { user, signOut } = useAuth();

    return (
        <LinearGradient
            colors={Colors.background.secondary ? [Colors.background.default, Colors.background.secondary] : ['#0a0a1a', '#12122a']}
            style={styles.container}
        >
            <SafeAreaView style={styles.safeArea}>
                <View style={styles.content}>
                    <Text style={styles.headerTitle}>Profile</Text>
                    <Text style={styles.headerSubtitle}>My Harmonic Journey</Text>

                    {/* Profile Card */}
                    <View style={styles.profileCard}>
                        <View style={styles.avatarContainer}>
                            <UserIcon size={32} color="white" />
                        </View>
                        <View style={styles.profileInfo}>
                            <Text style={styles.emailLabel}>Welcome,</Text>
                            <Text style={styles.emailText}>{user?.user_metadata?.display_name || user?.email || 'Guest User'}</Text>
                        </View>
                    </View>

                    {/* Settings / Menu */}
                    <View style={styles.menuContainer}>
                        <TouchableOpacity style={styles.menuItem}>
                            <View style={styles.menuIconBox}>
                                <Settings size={20} color={Colors.text.primary} />
                            </View>
                            <Text style={styles.menuText}>App Settings</Text>
                        </TouchableOpacity>

                        <TouchableOpacity style={styles.menuItem}>
                            <View style={styles.menuIconBox}>
                                <Award size={20} color={Colors.text.primary} />
                            </View>
                            <Text style={styles.menuText}>Your Stats</Text>
                        </TouchableOpacity>
                    </View>

                    {/* Logout Button */}
                    <TouchableOpacity style={styles.logoutBtn} onPress={signOut}>
                        <LogOut size={20} color="#ef4444" />
                        <Text style={styles.logoutText}>Sign Out</Text>
                    </TouchableOpacity>

                    <Text style={styles.versionText}>Harmonic Beacon v1.0.0</Text>
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
    profileCard: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: 'rgba(255,255,255,0.05)',
        padding: 16,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: Colors.border.subtle,
        marginBottom: 32,
        gap: 16,
    },
    avatarContainer: {
        width: 56,
        height: 56,
        borderRadius: 28,
        backgroundColor: Colors.primary[600],
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: Colors.primary[500],
        shadowOffset: { width: 0, height: 0 },
        shadowOpacity: 0.5,
        shadowRadius: 10,
        elevation: 5,
    },
    profileInfo: {
        flex: 1,
    },
    emailLabel: {
        fontSize: 12,
        color: Colors.text.secondary,
        marginBottom: 2,
    },
    emailText: {
        fontSize: 16,
        fontWeight: '600',
        color: Colors.text.primary,
    },
    menuContainer: {
        backgroundColor: 'rgba(255,255,255,0.02)',
        borderRadius: 16,
        overflow: 'hidden',
        marginBottom: 32,
    },
    menuItem: {
        flexDirection: 'row',
        alignItems: 'center',
        padding: 16,
        gap: 16,
        borderBottomWidth: 1,
        borderBottomColor: 'rgba(255,255,255,0.05)',
    },
    menuIconBox: {
        width: 36,
        height: 36,
        borderRadius: 10,
        backgroundColor: 'rgba(255,255,255,0.1)',
        alignItems: 'center',
        justifyContent: 'center',
    },
    menuText: {
        fontSize: 16,
        color: Colors.text.primary,
    },
    logoutBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 16,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: 'rgba(239, 68, 68, 0.3)',
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        gap: 8,
    },
    logoutText: {
        color: '#ef4444',
        fontSize: 16,
        fontWeight: '600',
    },
    versionText: {
        textAlign: 'center',
        color: Colors.text.muted,
        fontSize: 12,
        marginTop: 24,
    }
});
