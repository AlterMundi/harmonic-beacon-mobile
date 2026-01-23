import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View } from 'react-native';
import { Colors } from '../constants/Colors';
import { AuthProvider } from '../context/AuthContext';
import { AudioProvider } from '../context/AudioContext';

export default function RootLayout() {
    return (
        <AuthProvider>
            <AudioProvider>
                <View style={{ flex: 1, backgroundColor: Colors.background.default }}>
                    <StatusBar style="light" />
                    <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: Colors.background.default } }}>
                        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
                        <Stack.Screen name="(auth)" options={{ headerShown: false }} />
                    </Stack>
                </View>
            </AudioProvider>
        </AuthProvider>
    );
}
