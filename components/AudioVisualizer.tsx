import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Animated } from 'react-native';
import { Colors } from '../constants/Colors';

interface AudioVisualizerProps {
    isPlaying?: boolean;
    barCount?: number;
}

export function AudioVisualizer({ isPlaying = true, barCount = 5 }: AudioVisualizerProps) {
    const animations = useRef(
        [...Array(barCount)].map(() => new Animated.Value(10))
    ).current;
    const compositeRef = useRef<Animated.CompositeAnimation | null>(null);

    useEffect(() => {
        if (isPlaying) {
            const createAnimation = (anim: Animated.Value, delay: number) => {
                return Animated.loop(
                    Animated.sequence([
                        Animated.timing(anim, {
                            toValue: Math.random() * 40 + 10,
                            duration: 400,
                            delay,
                            useNativeDriver: false,
                        }),
                        Animated.timing(anim, {
                            toValue: 10,
                            duration: 400,
                            useNativeDriver: false,
                        }),
                    ])
                );
            };

            const runningAnimations = animations.map((anim, i) =>
                createAnimation(anim, i * 100)
            );

            const composite = Animated.parallel(runningAnimations);
            compositeRef.current = composite;
            composite.start();
        } else {
            compositeRef.current?.stop();
            compositeRef.current = null;
            animations.forEach(anim => anim.setValue(10));
        }

        return () => {
            compositeRef.current?.stop();
            compositeRef.current = null;
        };
    }, [isPlaying, animations]);

    return (
        <View style={styles.container}>
            {animations.map((anim, i) => (
                <Animated.View
                    key={i}
                    style={[
                        styles.bar,
                        {
                            height: anim,
                            backgroundColor: Colors.primary[400],
                            opacity: 0.8,
                        },
                    ]}
                />
            ))}
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
        height: 60,
    },
    bar: {
        width: 6,
        borderRadius: 3,
    },
});
