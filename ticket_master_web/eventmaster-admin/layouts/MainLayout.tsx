import React, { useState, useEffect } from 'react';
import {
  Menu,
  X,
  Search,
  Bot,
  Sun,
  Moon,
  Bell,
  ChevronDown,
  Settings as SettingsIcon,
  LogOut,
  ChevronLeft,
  LayoutDashboard,
  Calendar,
  PieChart,
  Ticket,
  UserCheck,
  Wallet,
  Users as UsersIcon,
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { Tab } from '../types'; // Adjust path as needed
import logo from '../assets/logo.jpg'; // Adjust path

interface MainLayoutProps {
  children: React.ReactNode;
  activeTab: Tab;
  setActiveTab: (tab: Tab) => void;
}

const MainLayout: React.FC<MainLayoutProps> = ({ children, activeTab, setActiveTab }) => {
  const { adminInfo, logout } = useAuth();
  const { isDarkMode, toggleTheme } = useTheme();
  
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [showAccountMenu, setShowAccountMenu] = useState(false);

  // Responsive sidebar handling
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth < 768) {
        setIsSidebarOpen(false);
        setIsCollapsed(false); // Reset collapse on mobile
      } else {
        setIsSidebarOpen(true);
      }
    };
    window.addEventListener('resize', handleResize);
    handleResize(); // Initial check
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const NavItem = ({ tab, icon: Icon, label }: { tab: Tab; icon: any; label: string }) => (
    <button
      onClick={() => {
        setActiveTab(tab);
        if (window.innerWidth < 768) setIsSidebarOpen(false);
      }}
      className={`w-full flex items-center gap-2 py-2 rounded-lg transition-all duration-200 group relative ${activeTab === tab
        ? 'text-emerald-600 dark:text-emerald-400 font-medium'
        : 'text-gray-600 dark:text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400'
        } ${isCollapsed ? 'justify-center px-2' : 'px-3'}`}
      title={isCollapsed ? label : undefined}
    >
      <Icon className={`w-4 h-4 shrink-0 ${isCollapsed ? '' : ''}`} />
      {!isCollapsed && <span className="truncate whitespace-nowrap">{label}</span>}

      {/* Tooltip for collapsed mode */}
      {isCollapsed && (
        <div className="absolute left-full ml-2 px-2 py-1 bg-gray-900 text-white text-xs rounded opacity-0 group-hover:opacity-100 pointer-events-none whitespace-nowrap z-50 transition-opacity">
          {label}
        </div>
      )}
    </button>
  );

  return (
    <div className={`flex h-screen bg-gray-50 dark:bg-gray-900 transition-colors duration-300`}>
      {/* Mobile Sidebar Backdrop */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 backdrop-blur-sm z-30 md:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed md:relative z-40 h-full bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 transition-all duration-300 flex flex-col ${isSidebarOpen
          ? (isCollapsed ? 'md:w-24' : 'md:w-80') + ' w-80 translate-x-0 shadow-2xl md:shadow-none'
          : 'w-0 -translate-x-full overflow-hidden opacity-0 md:opacity-100 ' + (isCollapsed ? 'md:w-24' : 'md:w-80')
          }`}
      >
        <div className={`p-6 pt-4 flex items-start ${isCollapsed ? 'justify-center px-2' : 'justify-between'}`}>
          <div className="flex items-center justify-center w-full">
            <img src={logo} alt="EventMaster Logo" className="h-24 md:h-32 lg:h-40 w-auto object-contain transition-transform duration-500 hover:scale-110" />
          </div>

          <button onClick={() => setIsSidebarOpen(false)} className="md:hidden text-gray-500 absolute top-4 right-4">
            <X className="w-6 h-6" />
          </button>

          {/* Collapse Toggle Button (Desktop only) */}
          <button
            onClick={() => setIsCollapsed(!isCollapsed)}
            className={`hidden md:flex absolute -right-3 top-9 bg-white border border-gray-200 rounded-full p-1 text-gray-400 hover:text-emerald-600 shadow-sm transition-transform duration-300 z-30 ${isCollapsed ? 'rotate-180' : ''}`}
          >
            <ChevronLeft className="w-3 h-3" />
          </button>
        </div>

        <nav className="px-3 space-y-6 mt-0 flex-1 overflow-y-auto">
          {/* Vue d'ensemble */}
          {!isCollapsed && (
            <div className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider px-3 mb-2">
              Vue d'ensemble
            </div>
          )}
          <div className="space-y-1">
            <NavItem tab={Tab.DASHBOARD} icon={LayoutDashboard} label="Tableau de bord" />
            <NavItem tab={Tab.STATISTICS} icon={PieChart} label="Statistiques" />
          </div>

          {/* Gestion */}
          {!isCollapsed && (
            <div className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider px-3 mb-2 mt-6">
              Gestion
            </div>
          )}
          <div className="space-y-1">
            <NavItem tab={Tab.EVENTS} icon={Calendar} label="Évènements" />
            <NavItem tab={Tab.TICKETS} icon={Ticket} label="Billetterie" />
            <NavItem tab={Tab.CLIENTS} icon={UserCheck} label="Clients" />
            <NavItem tab={Tab.ACCOUNTS} icon={Wallet} label="Comptes" />
          </div>

          {/* Intelligence */}
          {!isCollapsed && (
            <div className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider px-3 mb-2 mt-6">
              Intelligence
            </div>
          )}
          <div className="space-y-1">
            <NavItem tab={Tab.AI_ASSISTANT} icon={Bot} label="Assistant IA" />
          </div>

          {/* Système */}
          {!isCollapsed && (
            <div className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider px-3 mb-2 mt-6">
              Système
            </div>
          )}
          <div className="space-y-1">
            <NavItem tab={Tab.USERS} icon={UsersIcon} label="Utilisateurs" />
            <NavItem tab={Tab.SETTINGS} icon={SettingsIcon} label="Paramètres" />
          </div>
        </nav>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col h-full overflow-hidden w-full">
        {/* Top Header */}
        <header className="h-20 bg-white/80 dark:bg-gray-800/80 backdrop-blur-md border-b border-gray-200/50 dark:border-gray-700/50 flex items-center justify-between px-8 shrink-0 z-10 sticky top-0">
          <div className="flex items-center gap-4 flex-1">
            {!isSidebarOpen && (
              <button onClick={() => setIsSidebarOpen(true)} className="p-2 text-gray-500 hover:text-gray-900 transition-colors">
                <Menu className="w-6 h-6" />
              </button>
            )}

            {/* Global Search Bar */}
            <div className="hidden md:flex items-center bg-white dark:bg-gray-800 border-2 border-transparent focus-within:border-emerald-500/50 rounded-2xl px-4 py-2.5 shadow-sm hover:shadow-md transition-all w-96 group">
              <Search className="w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
              <input
                type="text"
                placeholder="Rechercher un événement, un client..."
                className="bg-transparent border-none outline-none text-sm ml-3 w-full font-medium text-gray-700 dark:text-gray-200 placeholder-gray-400"
              />
            </div>
          </div>

          <div className="flex items-center gap-4">
            {/* Action Buttons */}
            <div className="flex items-center gap-2 mr-2">
              <button
                onClick={() => setActiveTab(Tab.AI_ASSISTANT)}
                className="p-2.5 text-gray-500 dark:text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400 rounded-xl transition-all"
                title="Ouvrir l'assistant IA"
              >
                <Bot className="w-5 h-5" />
              </button>
              <button
                onClick={toggleTheme}
                className="p-2.5 text-gray-500 dark:text-gray-400 hover:text-amber-500 rounded-xl transition-all"
                title={isDarkMode ? "Passer en mode clair" : "Passer en mode sombre"}
              >
                {isDarkMode ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
              </button>
              <button className="p-2.5 text-gray-500 dark:text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400 rounded-xl transition-all relative">
                <Bell className="w-5 h-5" />
                <span className="absolute top-2 right-2.5 w-2 h-2 bg-red-500 rounded-full border border-white dark:border-gray-800"></span>
              </button>
            </div>

            <div className="relative">
              <button
                onClick={() => setShowAccountMenu(!showAccountMenu)}
                className="hidden md:flex items-center gap-3 pl-2 pr-4 py-1.5 bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-md border border-gray-100 dark:border-gray-700 transition-all group"
              >
                {adminInfo?.photo_profil ? (
                  <img
                    src={adminInfo.photo_profil.startsWith('http') ? adminInfo.photo_profil : `http://localhost:8000${adminInfo.photo_profil}`}
                    alt="Profile"
                    className="w-8 h-8 rounded-full object-cover ring-2 ring-white"
                  />
                ) : (
                  <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-700 font-bold text-xs ring-2 ring-white">
                    {adminInfo ? `${adminInfo.prenom?.charAt(0) || ''}`.toUpperCase() || 'A' : 'A'}
                  </div>
                )}
                <div className="text-left hidden lg:block">
                  <p className="text-sm font-semibold text-gray-900 dark:text-gray-100 group-hover:text-emerald-600 transition-colors">
                    {adminInfo ? `${adminInfo.prenom || ''} ${adminInfo.nom || ''}`.trim() || 'Admin' : 'Admin'}
                  </p>
                  <p className="text-[10px] uppercase font-bold text-gray-400 tracking-wider">Super Admin</p>
                </div>
                <ChevronDown className="w-4 h-4 text-gray-400 group-hover:text-gray-600 transition-colors" />
              </button>

              {showAccountMenu && (
                <div className="absolute top-full right-0 mt-2 w-56 bg-white dark:bg-gray-800 rounded-xl shadow-xl border border-gray-200 dark:border-gray-700 py-2 z-50">
                  <div className="px-4 py-3 border-b border-gray-100 dark:border-gray-700">
                    <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                      {adminInfo ? `${adminInfo.prenom || ''} ${adminInfo.nom || ''}`.trim() || 'Admin User' : 'Admin User'}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">{adminInfo?.email || 'admin@event.com'}</p>
                  </div>
                  <button
                    onClick={() => setActiveTab(Tab.SETTINGS)}
                    className="w-full px-4 py-2 text-left text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 flex items-center gap-2 transition-colors"
                  >
                    <SettingsIcon className="w-4 h-4" />
                    Paramètres
                  </button>
                  <button
                    onClick={logout}
                    className="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 flex items-center gap-2 transition-colors"
                  >
                    <LogOut className="w-4 h-4" />
                    Déconnexion
                  </button>
                </div>
              )}
            </div>
           </div>
        </header>

        {/* Content Area */}
        <div className="flex-1 overflow-auto p-3 sm:p-4 md:p-6 bg-gray-50 dark:bg-gray-900">
            {children}
        </div>
      </main>
    </div>
  );
};

export default MainLayout;
