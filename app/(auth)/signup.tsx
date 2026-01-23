import { View, Text, StyleSheet, TextInput, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../context/AuthContext';
import { Mail, Lock, User, ArrowLeft } from 'lucide-react-native';

export default function SignupScreen() {
    const { signIn } = useAuth(); // Create account essentially signs you in for MVP
    const router = useRouter();

    const handleSignup = () => {
        signIn();
    };

    return (
        <LinearGradient
            colors={Colors.background.secondary ? [Colors.background.default, Colors.background.secondary] : ['#0a0a1a', '#12122a']}
            style={styles.container}
        >
            <SafeAreaView style={styles.safeArea}>
                <View style={styles.content}>
                    <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
                        <ArrowLeft color="white" size={24} />
                    </TouchableOpacity>

                    <View style={styles.header}>
                        <Text style={styles.title}>Create Account</Text>
                        <Text style={styles.subtitle}>Join the harmonic community</Text>
                    </View>

                    <View style={styles.form}>
                        <View style={styles.inputContainer}>
                            <User color={Colors.text.muted} size={20} />
                            <TextInput
                                placeholder="Full Name"
                                placeholderTextColor={Colors.text.muted}
                                style={styles.input}
                            />
                        </View>

                        <View style={styles.inputContainer}>
                            <Mail color={Colors.text.muted} size={20} />
                            <TextInput
                                placeholder="Email"
                                placeholderTextColor={Colors.text.muted}
                                style={styles.input}
                                autoCapitalize="none"
                            />
                        </View>

                        <View style={styles.inputContainer}>
                            <Lock color={Colors.text.muted} size={20} />
                            <TextInput
                                placeholder="Password"
                                placeholderTextColor={Colors.text.muted}
                                style={styles.input}
                                secureTextEntry
                            />
                        </View>

                        <TouchableOpacity style={styles.signupBtn} onPress={handleSignup}>
                            <Text style={styles.signupBtnText}>Create Account</Text>
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
        flex: 1,
        padding: 24,
    },
    backBtn: {
        width: 40,
        height: 40,
        justifyContent: 'center',
        marginBottom: 24,
    },
    header: {
        marginBottom: 32,
    },
    title: {
        fontSize: 32,
        fontWeight: '700',
        color: Colors.text.primary,
        marginBottom: 8,
    },
    subtitle: {
        fontSize: 16,
        color: Colors.text.secondary,
    },
    form: {
        gap: 16,
    },
    inputContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: 'rgba(255,255,255,0.05)',
        borderRadius: 12,
        paddingHorizontal: 16,
        height: 56,
        borderWidth: 1,
        borderColor: Colors.border.subtle,
        gap: 12,
    },
    input: {
        flex: 1,
        color: 'white',
        fontSize: 16,
    },
    signupBtn: {
        backgroundColor: Colors.primary[600],
        height: 56,
        borderRadius: 16,
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: 16,
    },
    signupBtnText: {
        color: 'white',
        fontSize: 16,
        fontWeight: '600',
    }
});
