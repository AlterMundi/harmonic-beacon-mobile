import React, { createContext, useContext } from 'react';

type AuthContextType = {
  isLoading: boolean;
};

const AuthContext = createContext<AuthContextType>({ isLoading: false });

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  return (
    <AuthContext.Provider value={{ isLoading: false }}>
      {children}
    </AuthContext.Provider>
  );
}
