import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface AdminInfo {
  id_admin?: string;
  id?: string;
  prenom?: string;
  nom?: string;
  email?: string;
  photo_profil?: string;
  [key: string]: any;
}

interface AuthContextType {
  isAuthenticated: boolean;
  adminInfo: AdminInfo | null;
  login: () => void;
  logout: () => void;
  fetchAdminData: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    const saved = localStorage.getItem('isAuthenticated');
    return saved === 'true';
  });
  const [adminInfo, setAdminInfo] = useState<AdminInfo | null>(null);

  const login = () => {
    setIsAuthenticated(true);
    localStorage.setItem('isAuthenticated', 'true');
  };

  const logout = () => {
    setIsAuthenticated(false);
    localStorage.removeItem('isAuthenticated');
    localStorage.removeItem('authToken');
    localStorage.removeItem('tokenExpiration');
    localStorage.removeItem('administrateur');
    setAdminInfo(null);
  };

  const fetchAdminData = async () => {
    try {
      const token = localStorage.getItem('authToken');
      const adminData = localStorage.getItem('administrateur');
      
      if (!adminData) {
        return;
      }

      const admin = JSON.parse(adminData);
      const adminId = admin.id_admin || admin.id;

      if (!adminId) {
        return;
      }

      const response = await fetch(`http://localhost:8000/api/administrateurs/${adminId}/`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement des données admin');
      }

      const data = await response.json();
      setAdminInfo(data);
    } catch (error) {
      console.error('Erreur lors du chargement des données admin:', error);
    }
  };

  useEffect(() => {
    // Check initial auth state, maybe validate token validity here
    if (isAuthenticated) {
        fetchAdminData();
    }
  }, [isAuthenticated]);

  return (
    <AuthContext.Provider value={{ isAuthenticated, adminInfo, login, logout, fetchAdminData }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
