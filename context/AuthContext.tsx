import React, { createContext, useContext, useState } from 'react';

type AuthContextType = {
  isLoading: boolean;
  user: any;
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  signUp: (email: string, password: string, name: string) => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
  signInWithGoogle: () => Promise<{ error: string | null }>;
  signInWithApple: () => Promise<{ error: string | null }>;
};

const AuthContext = createContext<AuthContextType>({
  isLoading: false,
  user: null,
  signIn: async () => ({ error: 'Auth not implemented (PoC stub)' }),
  signUp: async () => ({ error: 'Auth not implemented (PoC stub)' }),
  signOut: async () => {},
  signInWithGoogle: async () => ({ error: 'Auth not implemented (PoC stub)' }),
  signInWithApple: async () => ({ error: 'Auth not implemented (PoC stub)' }),
});

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [isLoading] = useState(false);

  const value: AuthContextType = {
    isLoading,
    user: null,
    signIn: async () => ({ error: 'Auth not implemented (PoC stub)' }),
    signUp: async () => ({ error: 'Auth not implemented (PoC stub)' }),
    signOut: async () => {
      console.log('[AuthContext] Sign out (stub — no-op in PoC)');
    },
    signInWithGoogle: async () => ({ error: 'Auth not implemented (PoC stub)' }),
    signInWithApple: async () => ({ error: 'Auth not implemented (PoC stub)' }),
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}
