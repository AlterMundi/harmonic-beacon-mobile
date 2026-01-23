import { View, Text, StyleSheet, TextInput, TouchableOpacity } from 'react-native';
import { Link, useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../context/AuthContext';
import { Mail, Lock, ArrowRight } from 'lucide-react-native';

export default function LoginScreen() {
    const { signIn } = useAuth();
    const router = useRouter();

    const handleLogin = () => {
        signIn(); // This simulates login and triggers the redirect in AuthContext
    };

    return (
        <LinearGradient
            colors={Colors.background.secondary ? [Colors.background.default, Colors.background.secondary] : ['#0a0a1a', '#12122a']}
            style={styles.container}
        >
            <SafeAreaView style={styles.safeArea}>
                <View style={styles.content}>
                    <View style={styles.header}>
                        <View style={styles.logoOrb} />
                        <Text style={styles.title}>Welcome Back</Text>
                        <Text style={styles.subtitle}>Sign in to your beacon</Text>
                    </View>

                    <View style={styles.form}>
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

                        <TouchableOpacity style={styles.forgotBtn}>
                            <Text style={styles.forgotText}>Forgot Password?</Text>
                        </TouchableOpacity>

                        <TouchableOpacity style={styles.loginBtn} onPress={handleLogin}>
                            <Text style={styles.loginBtnText}>Sign In</Text>
                            <ArrowRight color="white" size={20} />
                        </TouchableOpacity>
                    </View>

                    <View style={styles.footer}>
                        <Text style={styles.footerText}>Don't have an account? </Text>
                        <Link href="/signup" asChild>
                            <TouchableOpacity>
                                <Text style={styles.linkText}>Sign Up</Text>
                            </TouchableOpacity>
                        </Link>
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
        justifyContent: 'center',
    },
    header: {
        alignItems: 'center',
        marginBottom: 48,
    },
    logoOrb: {
        width: 80,
        height: 80,
        borderRadius: 40,
        backgroundColor: Colors.primary[600],
        marginBottom: 24,
        shadowColor: Colors.primary[500],
        shadowOffset: { width: 0, height: 0 },
        shadowOpacity: 0.5,
        shadowRadius: 30,
        elevation: 10,
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
    forgotBtn: {
        alignSelf: 'flex-end',
    },
    forgotText: {
        color: Colors.text.muted,
        fontSize: 14,
    },
    loginBtn: {
        backgroundColor: Colors.primary[600],
        height: 56,
        borderRadius: 16,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        marginTop: 8,
    },
    loginBtnText: {
        color: 'white',
        fontSize: 16,
        fontWeight: '600',
    },
    footer: {
        flexDirection: 'row',
        justifyContent: 'center',
        marginTop: 48,
    },
    footerText: {
        color: Colors.text.secondary,
        fontSize: 14,
    },
    linkText: {
        color: Colors.primary[400],
        fontSize: 14,
        fontWeight: '600',
    }
});
