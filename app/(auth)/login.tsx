import { View, Text, StyleSheet, TextInput, TouchableOpacity, ActivityIndicator, Platform } from 'react-native';
import { Link } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../context/AuthContext';
import { Mail, Lock, ArrowRight } from 'lucide-react-native';
import { useState } from 'react';
import * as AppleAuthentication from 'expo-apple-authentication';

export default function LoginScreen() {
    const { signIn, signInWithGoogle, signInWithApple } = useAuth();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [isSocialLoading, setIsSocialLoading] = useState<'google' | 'apple' | null>(null);
    const [error, setError] = useState<string | null>(null);

    const handleLogin = async () => {
        // Validate inputs
        if (!email.trim()) {
            setError('Please enter your email');
            return;
        }
        if (!password) {
            setError('Please enter your password');
            return;
        }

        setError(null);
        setIsLoading(true);

        const { error: authError } = await signIn(email.trim(), password);

        setIsLoading(false);

        if (authError) {
            setError(authError);
        }
        // Navigation is handled automatically by AuthContext
    };

    const handleGoogleSignIn = async () => {
        setError(null);
        setIsSocialLoading('google');

        const { error: authError } = await signInWithGoogle();

        setIsSocialLoading(null);

        if (authError) {
            setError(authError);
        }
    };

    const handleAppleSignIn = async () => {
        setError(null);
        setIsSocialLoading('apple');

        const { error: authError } = await signInWithApple();

        setIsSocialLoading(null);

        if (authError) {
            setError(authError);
        }
    };

    const isDisabled = isLoading || isSocialLoading !== null;

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
                        {error && (
                            <View style={styles.errorContainer}>
                                <Text style={styles.errorText}>{error}</Text>
                            </View>
                        )}

                        <View style={styles.inputContainer}>
                            <Mail color={Colors.text.muted} size={20} />
                            <TextInput
                                placeholder="Email"
                                placeholderTextColor={Colors.text.muted}
                                style={styles.input}
                                autoCapitalize="none"
                                keyboardType="email-address"
                                value={email}
                                onChangeText={setEmail}
                                editable={!isDisabled}
                            />
                        </View>

                        <View style={styles.inputContainer}>
                            <Lock color={Colors.text.muted} size={20} />
                            <TextInput
                                placeholder="Password"
                                placeholderTextColor={Colors.text.muted}
                                style={styles.input}
                                secureTextEntry
                                value={password}
                                onChangeText={setPassword}
                                editable={!isDisabled}
                            />
                        </View>

                        <TouchableOpacity style={styles.forgotBtn}>
                            <Text style={styles.forgotText}>Forgot Password?</Text>
                        </TouchableOpacity>

                        <TouchableOpacity
                            style={[styles.loginBtn, isDisabled && styles.loginBtnDisabled]}
                            onPress={handleLogin}
                            disabled={isDisabled}
                        >
                            {isLoading ? (
                                <ActivityIndicator color="white" />
                            ) : (
                                <>
                                    <Text style={styles.loginBtnText}>Sign In</Text>
                                    <ArrowRight color="white" size={20} />
                                </>
                            )}
                        </TouchableOpacity>

                        {/* Divider */}
                        <View style={styles.dividerContainer}>
                            <View style={styles.divider} />
                            <Text style={styles.dividerText}>or continue with</Text>
                            <View style={styles.divider} />
                        </View>

                        {/* Social Login Buttons */}
                        <View style={styles.socialButtonsContainer}>
                            <TouchableOpacity
                                style={[styles.socialButton, isDisabled && styles.socialButtonDisabled]}
                                onPress={handleGoogleSignIn}
                                disabled={isDisabled}
                            >
                                {isSocialLoading === 'google' ? (
                                    <ActivityIndicator color="white" size="small" />
                                ) : (
                                    <>
                                        <Text style={styles.socialIcon}>G</Text>
                                        <Text style={styles.socialButtonText}>Google</Text>
                                    </>
                                )}
                            </TouchableOpacity>

                            {Platform.OS === 'ios' && (
                                <TouchableOpacity
                                    style={[styles.socialButton, styles.appleButton, isDisabled && styles.socialButtonDisabled]}
                                    onPress={handleAppleSignIn}
                                    disabled={isDisabled}
                                >
                                    {isSocialLoading === 'apple' ? (
                                        <ActivityIndicator color="black" size="small" />
                                    ) : (
                                        <>
                                            <Text style={[styles.socialIcon, styles.appleIcon]}></Text>
                                            <Text style={[styles.socialButtonText, styles.appleButtonText]}>Apple</Text>
                                        </>
                                    )}
                                </TouchableOpacity>
                            )}
                        </View>
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
    errorContainer: {
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        borderWidth: 1,
        borderColor: 'rgba(239, 68, 68, 0.3)',
        borderRadius: 12,
        padding: 12,
    },
    errorText: {
        color: '#ef4444',
        fontSize: 14,
        textAlign: 'center',
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
    loginBtnDisabled: {
        opacity: 0.6,
    },
    loginBtnText: {
        color: 'white',
        fontSize: 16,
        fontWeight: '600',
    },
    dividerContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        marginVertical: 16,
    },
    divider: {
        flex: 1,
        height: 1,
        backgroundColor: Colors.border.subtle,
    },
    dividerText: {
        color: Colors.text.muted,
        fontSize: 14,
        marginHorizontal: 16,
    },
    socialButtonsContainer: {
        flexDirection: 'row',
        gap: 12,
    },
    socialButton: {
        flex: 1,
        height: 52,
        borderRadius: 12,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        backgroundColor: 'rgba(255,255,255,0.08)',
        borderWidth: 1,
        borderColor: Colors.border.subtle,
    },
    socialButtonDisabled: {
        opacity: 0.6,
    },
    socialIcon: {
        fontSize: 18,
        fontWeight: '700',
        color: 'white',
    },
    socialButtonText: {
        color: 'white',
        fontSize: 15,
        fontWeight: '500',
    },
    appleButton: {
        backgroundColor: 'white',
    },
    appleIcon: {
        color: 'black',
    },
    appleButtonText: {
        color: 'black',
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

