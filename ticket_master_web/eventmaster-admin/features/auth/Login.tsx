import React, { useState, useEffect } from 'react';
import { Mail, Lock, ArrowRight, Loader2 } from 'lucide-react';
import logo from '../../assets/logo.jpg';

interface LoginProps {
  onLogin: () => void;
}

export const Login: React.FC<LoginProps> = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [mot_de_passe, setMotDePasse] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [displayedText, setDisplayedText] = useState('');
  const fullText = "Gérez vos événements avec intelligence.";
  const [textIndex, setTextIndex] = useState(0);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      const response = await fetch('http://localhost:8000/api/auth/login/admin/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email,
          mot_de_passe,
        }),
      });

      const data = await response.json();

      if (response.ok) {
        // Stocker le token et les informations de l'administrateur
        if (data.token) {
          localStorage.setItem('authToken', data.token);
        }
        if (data.expiration) {
          localStorage.setItem('tokenExpiration', data.expiration);
        }
        if (data.administrateur) {
          localStorage.setItem('administrateur', JSON.stringify(data.administrateur));
        }
        console.log('Connexion réussie');
        onLogin();
      } else {
        // Gérer les erreurs de l'API
        setError(data.message || 'Identifiants incorrects. Veuillez réessayer.');
      }
    } catch (err) {
      console.error('Erreur de connexion:', err);
      setError('Erreur de connexion au serveur. Vérifiez que l\'API est accessible.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      if (textIndex < fullText.length) {
        setDisplayedText(fullText.slice(0, textIndex + 1));
        setTextIndex(textIndex + 1);
      } else {
        setTimeout(() => {
          setTextIndex(0);
          setDisplayedText('');
        }, 2000);
      }
    }, 100);

    return () => clearTimeout(timer);
  }, [textIndex]);

  return (
    <div className="min-h-screen flex bg-white font-sans">
      {/* Left Side - Hero Section */}
      <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden bg-gray-900">
        <div className="absolute inset-0">
          <img
            src="https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=2070&auto=format&fit=crop"
            alt="Event Crowd"
            className="w-full h-full object-cover opacity-40"
          />
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-900/90 to-black/60"></div>
        </div>

        <div className="relative z-10 p-16 flex flex-col justify-between h-full text-white">
          <div className="flex items-center gap-3">
            {/* Logo removed from here */}
          </div>

          <div className="max-w-xl mb-12">
            <h1 className="text-5xl font-bold mb-8 leading-tight">
              {displayedText}<span className="text-emerald-400 animate-pulse">|</span>
            </h1>
            <p className="text-lg text-gray-300 leading-relaxed font-light">
              La plateforme tout-en-un pour créer, vendre et analyser vos événements.
              Optimisée par l'IA pour maximiser vos revenus et sécuriser vos entrées.
            </p>
          </div>

          <div className="flex items-center gap-4 text-sm text-gray-400">
          </div>
        </div>
      </div>

      {/* Right Side - Login Form */}
      <div className="flex-1 flex items-center justify-center p-4 sm:p-12 lg:p-24 relative">
        {/* Decorative elements */}
        <div className="absolute top-0 right-0 w-64 h-64 bg-emerald-50 rounded-bl-full opacity-50 -z-10"></div>
        <div className="absolute bottom-0 left-0 w-32 h-32 bg-gray-50 rounded-tr-full opacity-50 -z-10"></div>

        <div className="w-full max-w-md space-y-8">
          <div className="text-center">
            <div className="flex justify-center mb-6">
              <img src={logo} alt="EventMaster Logo" className="h-24 sm:h-32 md:h-40 lg:h-52 w-auto" />
            </div>
            <h2 className="text-3xl font-bold text-gray-900 tracking-tight">Bon retour parmi nous</h2>
            <p className="mt-2 text-gray-500">
              Saisissez vos identifiants pour accéder au tableau de bord.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-4 sm:mt-6 md:mt-8 space-y-4 sm:space-y-6">
            <div className="space-y-3 sm:space-y-5">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Adresse Email</label>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Mail className="h-5 w-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors duration-300" />
                  </div>
                  <input
                    type="email"
                    required
                    className="block w-full pl-11 pr-4 py-3 sm:py-4 border border-gray-200 hover:border-gray-300 rounded-xl bg-white text-gray-900 placeholder-gray-500/70 text-[15px] font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all duration-300 shadow-sm caret-emerald-600"
                    placeholder="nom@exemple.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-sm font-medium text-gray-700">Mot de passe</label>
                  <a href="#" className="text-sm font-medium text-emerald-600 hover:text-emerald-500">Mot de passe oublié ?</a>
                </div>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Lock className="h-5 w-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors duration-300" />
                  </div>
                  <input
                    type="password"
                    required
                    className="block w-full pl-11 pr-4 py-3 sm:py-4 border border-gray-200 hover:border-gray-300 rounded-xl bg-white text-gray-900 placeholder-gray-500/70 text-[15px] font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all duration-300 shadow-sm caret-emerald-600"
                    placeholder="••••••••"
                    value={mot_de_passe}
                    onChange={(e) => setMotDePasse(e.target.value)}
                  />
                </div>
              </div>
            </div>

            <div className="flex items-center">
              <input
                id="remember-me"
                name="remember-me"
                type="checkbox"
                className="h-4 w-4 text-emerald-600 focus:ring-emerald-500 border-gray-300 rounded cursor-pointer"
              />
              <label htmlFor="remember-me" className="ml-2 block text-sm text-gray-600 cursor-pointer select-none">
                Se souvenir de moi pendant 30 jours
              </label>
            </div>

            {error && (
              <div className="p-4 bg-red-50 text-red-600 text-sm rounded-xl flex items-center gap-3">
                <div className="w-2 h-2 rounded-full bg-red-600 shrink-0"></div>
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={isLoading}
              className="group w-full flex items-center justify-center py-4 px-4 border border-transparent rounded-xl shadow-lg text-base font-bold text-white bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-600 hover:to-teal-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500 transition-all duration-300 transform hover:scale-105 hover:shadow-xl disabled:opacity-70 disabled:cursor-not-allowed disabled:transform-none disabled:hover:scale-100"
            >
              {isLoading ? (
                <>
                  <Loader2 className="animate-spin -ml-1 mr-3 h-5 w-5" />
                  Connexion en cours...
                </>
              ) : (
                <>
                  Se connecter
                  <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
                </>
              )}
            </button>
          </form>

          <div className="mt-6 sm:mt-8 md:mt-12 pt-4 sm:pt-6 border-t border-gray-100 text-center">
            <p className="text-xs text-gray-400 font-medium">
              &copy; 2024 EventMaster Inc. Tous droits réservés.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
