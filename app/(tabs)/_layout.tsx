import { Tabs } from 'expo-router';
import { View } from 'react-native';
import { Radio, Moon, Heart } from 'lucide-react-native'; // Using Lucide icons
import { Colors } from '../../constants/Colors';
import { BlurView } from 'expo-blur';

export default function TabLayout() {
    return (
        <Tabs
            screenOptions={{
                headerShown: false,
                tabBarStyle: {
                    backgroundColor: Colors.background.secondary, // Fallback
                    position: 'absolute',
                    borderTopWidth: 0,
                    elevation: 0,
                    height: 80,
                    paddingBottom: 20,
                    paddingTop: 10,
                },
                tabBarBackground: () => (
                    <BlurView
                        tint="dark"
                        intensity={80}
                        style={{
                            position: 'absolute',
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            backgroundColor: 'rgba(10, 10, 26, 0.85)',
                            borderTopWidth: 1,
                            borderTopColor: Colors.border.subtle,
                        }}
                    />
                ),
                tabBarActiveTintColor: Colors.primary[400],
                tabBarInactiveTintColor: Colors.text.muted,
            }}
        >
            <Tabs.Screen
                name="index"
                options={{
                    title: 'Live',
                    tabBarIcon: ({ color, size }) => (
                        <View style={{ alignItems: 'center', justifyContent: 'center' }}>
                            <Radio size={size} color={color} />
                        </View>
                    ),
                }}
            />

            <Tabs.Screen
                name="meditate"
                options={{
                    title: 'Meditate',
                    tabBarIcon: ({ color, size }) => (
                        <Moon size={size} color={color} />
                    ),
                }}
            />

            <Tabs.Screen
                name="sessions"
                options={{
                    title: 'Sessions',
                    tabBarIcon: ({ color, size }) => (
                        <Heart size={size} color={color} />
                    ),
                }}
            />
        </Tabs>
    );
}
