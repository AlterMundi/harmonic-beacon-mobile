import { View, Text, StyleSheet, TextInput, TouchableOpacity, ActivityIndicator, Alert, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/Colors';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../context/AuthContext';
import { Mail, Lock, User, ArrowLeft } from 'lucide-react-native';
import { useState } from 'react';

export default function SignupScreen() {
    const { signUp, signInWithGoogle, signInWithApple } = useAuth();
    const router = useRouter();

    const [fullName, setFullName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [isSocialLoading, setIsSocialLoading] = useState<'google' | 'apple' | null>(null);
    const [error, setError] = useState<string | null>(null);

    const handleSignup = async () => {
        // Validation
        if (!fullName.trim() || !email.trim() || !password || !confirmPassword) {
            setError('Please fill in all fields');
            return;
        }

        if (password !== confirmPassword) {
            setError('Passwords do not match');
            return;
        }

        if (password.length < 6) {
            setError('Password must be at least 6 characters');
            return;
        }

        setError(null);
        setIsLoading(true);

        const { error: authError } = await signUp(email.trim(), password, fullName.trim());

        setIsLoading(false);

        if (authError) {
            setError(authError);
        } else {
            // Success! Supabase sends an email confirmation link by default
            Alert.alert(
                'Account Created',
                'Please check your email to verify your account before logging in.',
                [{ text: 'OK', onPress: () => router.back() }]
            );
        }
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
                    <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
                        <ArrowLeft color="white" size={24} />
                    </TouchableOpacity>

                    <View style={styles.header}>
                        <Text style={styles.title}>Create Account</Text>
                        <Text style={styles.subtitle}>Join the harmonic community</Text>
                    </View>

                    <View style={styles.form}>
                        {error && (
                            <View style={styles.errorContainer}>
                                <Text style={styles.errorText}>{error}</Text>
                            </View>
                        )}

                        <View style={styles.inputContainer}>
                            <User color={Colors.text.muted} size={20} />
                            <TextInput
                                placeholder="Full Name"
                                placeholderTextColor={Colors.text.muted}
                                style={styles.input}
                                autoCapitalize="words"
                                value={fullName}
                                onChangeText={setFullName}
                                editable={!isDisabled}
                            />
                        </View>

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

                        <View style={styles.inputContainer}>
                            <Lock color={Colors.text.muted} size={20} />
                            <TextInput
                                placeholder="Confirm Password"
                                placeholderTextColor={Colors.text.muted}
                                style={styles.input}
                                secureTextEntry
                                value={confirmPassword}
                                onChangeText={setConfirmPassword}
                                editable={!isDisabled}
                            />
                        </View>

                        <TouchableOpacity
                            style={[styles.signupBtn, isDisabled && styles.signupBtnDisabled]}
                            onPress={handleSignup}
                            disabled={isDisabled}
                        >
                            {isLoading ? (
                                <ActivityIndicator color="white" />
                            ) : (
                                <Text style={styles.signupBtnText}>Create Account</Text>
                            )}
                        </TouchableOpacity>

                        {/* Divider */}
                        <View style={styles.dividerContainer}>
                            <View style={styles.divider} />
                            <Text style={styles.dividerText}>or sign up with</Text>
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
    signupBtn: {
        backgroundColor: Colors.primary[600],
        height: 56,
        borderRadius: 16,
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: 16,
    },
    signupBtnDisabled: {
        opacity: 0.6,
    },
    signupBtnText: {
        color: 'white',
        fontSize: 16,
        fontWeight: '600',
    },
    dividerContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        marginVertical: 8,
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
});

