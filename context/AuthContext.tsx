import React, { createContext, useContext, useState, useEffect } from 'react';
import { useRouter, useSegments } from 'expo-router';
import { Platform } from 'react-native';
import { supabase } from '../lib/supabase';
import { Session, User } from '@supabase/supabase-js';
import * as AppleAuthentication from 'expo-apple-authentication';
import * as AuthSession from 'expo-auth-session';
import * as Crypto from 'expo-crypto';

import * as WebBrowser from 'expo-web-browser';

// Ensure WebBrowser auth sessions are closed properly
WebBrowser.maybeCompleteAuthSession();

type AuthContextType = {
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  signUp: (email: string, password: string, displayName: string) => Promise<{ error: string | null }>;
  signInWithGoogle: () => Promise<{ error: string | null }>;
  signInWithApple: () => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
  user: User | null;
  session: Session | null;
  isLoading: boolean;
};

const AuthContext = createContext<AuthContextType>({
  signIn: async () => ({ error: null }),
  signUp: async () => ({ error: null }),
  signInWithGoogle: async () => ({ error: null }),
  signInWithApple: async () => ({ error: null }),
  signOut: async () => { },
  user: null,
  session: null,
  isLoading: true,
});

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();
  const segments = useSegments();

  // Initialize - check for existing session
  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setIsLoading(false);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      setIsLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  // Handle navigation based on auth state
  useEffect(() => {
    if (isLoading) return;

    const inAuthGroup = segments[0] === '(auth)';

    if (!user && !inAuthGroup) {
      // Not logged in, redirect to login
      router.replace('/(auth)/login');
    } else if (user && inAuthGroup) {
      // Logged in, redirect to main app
      router.replace('/(tabs)');
    }
  }, [user, segments, isLoading]);

  const signIn = async (email: string, password: string): Promise<{ error: string | null }> => {
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        return { error: error.message };
      }
      return { error: null };
    } catch (err) {
      return { error: 'An unexpected error occurred' };
    }
  };

  const signUp = async (email: string, password: string, displayName: string): Promise<{ error: string | null }> => {
    try {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            display_name: displayName,
          },
        },
      });

      if (error) {
        return { error: error.message };
      }
      return { error: null };
    } catch (err) {
      return { error: 'An unexpected error occurred' };
    }
  };

  // Google Sign-In using Supabase OAuth with expo-web-browser
  const signInWithGoogle = async (): Promise<{ error: string | null }> => {
    try {
      // Create a redirect URL for the OAuth flow
      // Don't use custom scheme in Expo Go - it only works in standalone builds
      const redirectUrl = AuthSession.makeRedirectUri({
        // This will generate the correct URL for Expo Go or standalone apps
        native: 'harmonicbeacon://auth/callback',
      });

      console.log('OAuth redirect URL:', redirectUrl);

      // Get the OAuth URL from Supabase
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: redirectUrl,
          skipBrowserRedirect: true,
        },
      });

      if (error) {
        return { error: error.message };
      }

      if (!data.url) {
        return { error: 'Failed to get OAuth URL' };
      }

      console.log('Opening OAuth URL:', data.url);

      // Open the OAuth flow in a browser using WebBrowser
      const result = await WebBrowser.openAuthSessionAsync(data.url, redirectUrl);

      console.log('OAuth result:', result);

      if (result.type === 'success' && result.url) {
        // Extract the access token and refresh token from the URL
        const url = new URL(result.url);
        const hashParams = new URLSearchParams(url.hash.substring(1));
        const accessToken = hashParams.get('access_token');
        const refreshToken = hashParams.get('refresh_token');

        if (accessToken) {
          const { error: sessionError } = await supabase.auth.setSession({
            access_token: accessToken,
            refresh_token: refreshToken || '',
          });

          if (sessionError) {
            return { error: sessionError.message };
          }
          return { error: null };
        }
      } else if (result.type === 'cancel') {
        return { error: 'Sign-in was cancelled' };
      }

      return { error: 'Failed to complete sign-in' };
    } catch (err: any) {
      console.error('Google Sign-In error:', err);
      return { error: err.message || 'An unexpected error occurred' };
    }
  };

  // Apple Sign-In using native expo-apple-authentication
  const signInWithApple = async (): Promise<{ error: string | null }> => {
    try {
      if (Platform.OS !== 'ios') {
        return { error: 'Apple Sign-In is only available on iOS' };
      }

      // Check if Apple Sign-In is available
      const isAvailable = await AppleAuthentication.isAvailableAsync();
      if (!isAvailable) {
        return { error: 'Apple Sign-In is not available on this device' };
      }

      // Generate a nonce for security
      const rawNonce = Crypto.randomUUID();
      const hashedNonce = await Crypto.digestStringAsync(
        Crypto.CryptoDigestAlgorithm.SHA256,
        rawNonce
      );

      // Request Apple credentials
      const credential = await AppleAuthentication.signInAsync({
        requestedScopes: [
          AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
          AppleAuthentication.AppleAuthenticationScope.EMAIL,
        ],
      });

      if (credential.identityToken) {
        // Sign in with Supabase using the Apple ID token
        const { error } = await supabase.auth.signInWithIdToken({
          provider: 'apple',
          token: credential.identityToken,
          nonce: rawNonce,
        });

        if (error) {
          return { error: error.message };
        }
        return { error: null };
      }

      return { error: 'Could not get Apple credentials' };
    } catch (err: any) {
      if (err.code === 'ERR_REQUEST_CANCELED') {
        return { error: 'Sign-in was cancelled' };
      }
      return { error: err.message || 'An unexpected error occurred' };
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  return (
    <AuthContext.Provider
      value={{
        signIn,
        signUp,
        signInWithGoogle,
        signInWithApple,
        signOut,
        user,
        session,
        isLoading,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
