import React, { useState, useMemo, useEffect } from 'react';
import {
    Trophy,
    TrendingUp,
    DollarSign,
    User,
    Crown,
    ShoppingBag,
    Search,
    Filter,
    ArrowUpDown,
    MoreHorizontal,
    Download,
    Mail,
    Phone,
    MapPin,
    Calendar,
    Grid,
    List,
    Award,
    X,
    Users,
    Plus
} from 'lucide-react';

// ... (Keep existing types and mock data generator for brevity, assuming standard imports) ...
// --- Types & Interfaces ---
interface Client {
    id: string;
    name: string;
    email: string;
    phone: string;
    location: string;
    joinDate: string;
    status: 'Actif' | 'Inactif' | 'VIP' | 'Bloqué';
    ordersCount: number;
    totalSpent: number;
    referrals: number;
    lastActive: string;
    avatar: string;
}

const generateClients = (count: number): Client[] => {
    const statuses: Client['status'][] = ['Actif', 'Actif', 'Actif', 'VIP', 'Inactif', 'Bloqué'];
    const locations = ['Paris', 'Lyon', 'Marseille', 'Bordeaux', 'Lille', 'Nice'];

    return Array.from({ length: count }, (_, i) => ({
        id: `cl_${i + 1}`,
        name: `Client ${i + 1}`,
        email: `client${i + 1}@example.com`,
        phone: `06 ${Math.floor(Math.random() * 90) + 10} ${Math.floor(Math.random() * 90) + 10} ${Math.floor(Math.random() * 90) + 10} ${Math.floor(Math.random() * 90) + 10}`,
        location: locations[Math.floor(Math.random() * locations.length)],
        joinDate: new Date(2023, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28)).toLocaleDateString('fr-FR'),
        status: statuses[Math.floor(Math.random() * statuses.length)],
        ordersCount: Math.floor(Math.random() * 50),
        totalSpent: Math.floor(Math.random() * 5000),
        referrals: Math.floor(Math.random() * 15),
        lastActive: ['Aujourd\'hui', 'Hier', 'Il y a 3 jours', 'Il y a 1 semaine'][Math.floor(Math.random() * 4)],
        avatar: `https://i.pravatar.cc/150?u=${i + 100}`
    }));
};

import { CreateClientModal } from './CreateClientModal';
// Fixed Mock Data with Key Persona
const mockClientsList = generateClients(25);
mockClientsList[0] = { ...mockClientsList[0], name: "Sophie Martin", referrals: 145, ordersCount: 12, totalSpent: 1200, status: 'VIP', avatar: "https://i.pravatar.cc/150?u=30" };
mockClientsList[1] = { ...mockClientsList[1], name: "Thomas Dubreuil", referrals: 98, ordersCount: 8, totalSpent: 800, status: 'Actif', avatar: "https://i.pravatar.cc/150?u=33" };
mockClientsList[2] = { ...mockClientsList[2], name: "Maxime Richard", referrals: 12, ordersCount: 45, totalSpent: 4500, status: 'VIP', avatar: "https://i.pravatar.cc/150?u=20" };

export const Clients: React.FC = () => {
    const [viewMode, setViewMode] = useState<'table' | 'cards'>('table');
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [sortBy, setSortBy] = useState<string>('spent');
    const [selectedClients, setSelectedClients] = useState<string[]>([]);
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
    const [clients, setClients] = useState<Client[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [showAllAmbassadors, setShowAllAmbassadors] = useState(false);
    const [showAllSpenders, setShowAllSpenders] = useState(false);
    const [showEmailModal, setShowEmailModal] = useState(false);
    const [emailSubject, setEmailSubject] = useState('');
    const [emailMessage, setEmailMessage] = useState('');

    // Charger les clients depuis l'API
    useEffect(() => {
        const fetchClients = async () => {
            try {
                const token = localStorage.getItem('authToken');
                const response = await fetch('http://localhost:8000/api/utilisateurs/', {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!response.ok) {
                    throw new Error('Erreur lors du chargement des clients');
                }

                const data = await response.json();
                console.log('Clients data:', data);
                
                // Mapper les données de l'API vers le format Client
                const mappedClients: Client[] = data.results.map((user: any) => {
                    // Mapper le statut
                    let status: Client['status'] = 'Actif';
                    if (user.statut === 'actif') status = 'Actif';
                    else if (user.statut === 'inactif') status = 'Inactif';
                    else if (user.statut === 'vip') status = 'VIP';
                    else if (user.statut === 'bloqué' || user.statut === 'bloque') status = 'Bloqué';

                    // Formater la date de dernière activité
                    let lastActive = 'Jamais';
                    if (user.last_login) {
                        const lastLoginDate = new Date(user.last_login);
                        const now = new Date();
                        const diffTime = Math.abs(now.getTime() - lastLoginDate.getTime());
                        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                        
                        if (diffDays === 0) lastActive = 'Aujourd\'hui';
                        else if (diffDays === 1) lastActive = 'Hier';
                        else if (diffDays < 7) lastActive = `Il y a ${diffDays} jours`;
                        else lastActive = `Il y a ${Math.floor(diffDays / 7)} semaine(s)`;
                    }

                    return {
                        id: user.id_utilisateur.toString(),
                        name: user.nom_complet || `${user.prenom} ${user.nom}`,
                        email: user.email || '',
                        phone: user.tel || 'Non renseigné',
                        location: user.adresse || 'Non renseigné',
                        joinDate: new Date().toLocaleDateString('fr-FR'), // Pas de date dans l'API
                        status: status,
                        ordersCount: 0, // Pas disponible dans l'API
                        totalSpent: parseFloat(user.solde || '0'),
                        referrals: user.total_code_use || 0,
                        lastActive: lastActive,
                        avatar: user.photo_profil 
                            ? (user.photo_profil.startsWith('http') ? user.photo_profil : `http://localhost:8000${user.photo_profil}`)
                            : `https://ui-avatars.com/api/?name=${encodeURIComponent(user.nom_complet || user.prenom)}&background=10b981&color=fff`
                    };
                });

                setClients(mappedClients);
            } catch (error) {
                console.error('Erreur lors du chargement des clients:', error);
                alert('Erreur lors du chargement des clients');
            } finally {
                setIsLoading(false);
            }
        };

        fetchClients();
    }, []);


    const handleCreateClient = (newClient: any) => {
        // Recharger les clients depuis l'API
        const fetchClients = async () => {
            try {
                const token = localStorage.getItem('authToken');
                const response = await fetch('http://localhost:8000/api/utilisateurs/', {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!response.ok) {
                    throw new Error('Erreur lors du chargement des clients');
                }

                const data = await response.json();
                
                const mappedClients: Client[] = data.results.map((user: any) => {
                    let status: Client['status'] = 'Actif';
                    if (user.statut === 'actif') status = 'Actif';
                    else if (user.statut === 'inactif') status = 'Inactif';
                    else if (user.statut === 'vip') status = 'VIP';
                    else if (user.statut === 'bloqué' || user.statut === 'bloque') status = 'Bloqué';

                    let lastActive = 'Jamais';
                    if (user.last_login) {
                        const lastLoginDate = new Date(user.last_login);
                        const now = new Date();
                        const diffTime = Math.abs(now.getTime() - lastLoginDate.getTime());
                        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                        
                        if (diffDays === 0) lastActive = "Aujourd'hui";
                        else if (diffDays === 1) lastActive = 'Hier';
                        else if (diffDays < 7) lastActive = `Il y a ${diffDays} jours`;
                        else lastActive = `Il y a ${Math.floor(diffDays / 7)} semaine(s)`;
                    }

                    return {
                        id: user.id_utilisateur.toString(),
                        name: user.nom_complet || `${user.prenom} ${user.nom}`,
                        email: user.email || '',
                        phone: user.tel || 'Non renseigné',
                        location: user.adresse || 'Non renseigné',
                        joinDate: new Date().toLocaleDateString('fr-FR'),
                        status: status,
                        ordersCount: 0,
                        totalSpent: parseFloat(user.solde || '0'),
                        referrals: user.total_code_use || 0,
                        lastActive: lastActive,
                        avatar: user.photo_profil 
                            ? (user.photo_profil.startsWith('http') ? user.photo_profil : `http://localhost:8000${user.photo_profil}`)
                            : `https://ui-avatars.com/api/?name=${encodeURIComponent(user.nom_complet || user.prenom)}&background=10b981&color=fff`
                    };
                });

                setClients(mappedClients);
            } catch (error) {
                console.error('Erreur lors du chargement des clients:', error);
            }
        };

        fetchClients();
        setIsCreateModalOpen(false);
    };

    // Selection Handlers
    const handleSelectAll = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.checked) {
            setSelectedClients(currentClients.map(c => c.id));
        } else {
            setSelectedClients([]);
        }
    };

    const handleSelectOne = (id: string) => {
        if (selectedClients.includes(id)) {
            setSelectedClients(selectedClients.filter(cId => cId !== id));
        } else {
            setSelectedClients([...selectedClients, id]);
        }
    };

    const handleBulkEmail = () => {
        setShowEmailModal(true);
    };

    const handleSendEmail = () => {
        if (!emailSubject.trim() || !emailMessage.trim()) {
            alert('Veuillez remplir tous les champs');
            return;
        }
        console.log('Email envoyé à:', selectedClients.length, 'clients');
        console.log('Sujet:', emailSubject);
        console.log('Message:', emailMessage);
        alert(`Email envoyé avec succès à ${selectedClients.length} client(s)`);
        setShowEmailModal(false);
        setEmailSubject('');
        setEmailMessage('');
        setSelectedClients([]);
    };

    // Stats Logic
    const topAmbassadors = [...clients].sort((a, b) => b.referrals - a.referrals);
    const topSpenders = [...clients].sort((a, b) => b.totalSpent - a.totalSpent);

    // Filtered Content
    const filteredClients = useMemo(() => {
        let result = clients.filter(c =>
            (c.name.toLowerCase().includes(searchTerm.toLowerCase()) || c.email.toLowerCase().includes(searchTerm.toLowerCase())) &&
            (statusFilter === 'all' || c.status === statusFilter)
        );

        result.sort((a, b) => {
            if (sortBy === 'spent') return b.totalSpent - a.totalSpent;
            if (sortBy === 'orders') return b.ordersCount - a.ordersCount;
            if (sortBy === 'referrals') return b.referrals - a.referrals; // Important for Ambassador logic
            if (sortBy === 'name') return a.name.localeCompare(b.name);
            return 0;
        });

        return result;
    }, [clients, searchTerm, statusFilter, sortBy]);

    const currentClients = filteredClients; // Alias for cleaner usage in handlers

    if (isLoading) {
        return (
            <div className="flex items-center justify-center min-h-[500px]">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-600 mx-auto"></div>
                    <p className="text-gray-500 dark:text-gray-400 mt-4">Chargement des clients...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-8 animation-fade-in relative pb-10">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
                            <Users className="w-6 h-6 text-white" />
                        </div>
                        Clients & Communauté
                    </h1>
                    <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Vue unifiée de votre base client
                    </p>
                </div>
            </div>

            <CreateClientModal
                isOpen={isCreateModalOpen}
                onClose={() => setIsCreateModalOpen(false)}
                onSubmit={handleCreateClient}
            />

            {/* --- TOP SECTION: HIGHLIGHTS (Always Visible) --- */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Top Ambassadeurs Card */}
                <div className="bg-gradient-to-br from-orange-50 to-white dark:from-orange-900 dark:to-gray-800 rounded-xl border border-orange-100 dark:border-orange-700 p-5 shadow-sm relative overflow-visible group">
                    <div className="absolute top-0 right-0 p-3 opacity-10"><Crown className="w-16 h-16 text-orange-500 dark:text-orange-400" /></div>
                    <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-4 flex items-center justify-between">
                        <span className="flex items-center gap-2">
                            <span className="bg-orange-100 dark:bg-orange-800 p-1.5 rounded-md text-orange-600 dark:text-orange-400"><Trophy className="w-4 h-4" /></span>
                            Top Ambassadeurs
                        </span>
                        {topAmbassadors.length > 3 && (
                            <button
                                type="button"
                                onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    console.log('Ambassadors clicked:', showAllAmbassadors);
                                    setShowAllAmbassadors(!showAllAmbassadors);
                                }}
                                className="text-xs font-medium text-orange-600 hover:text-orange-700 dark:text-orange-400 dark:hover:text-orange-300 transition-colors cursor-pointer z-10 relative"
                            >
                                {showAllAmbassadors ? 'Voir moins' : `Voir plus (${topAmbassadors.length})`}
                            </button>
                        )}
                    </h3>
                    <div className={`grid gap-3 ${showAllAmbassadors ? 'grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4' : 'grid-cols-1 sm:grid-cols-3'}`}>
                        {topAmbassadors.slice(0, showAllAmbassadors ? topAmbassadors.length : 3).map((client, i) => (
                            <div key={client.id} className="text-center p-3 rounded-lg bg-orange-50/50 dark:bg-orange-900/50 hover:bg-white dark:hover:bg-gray-700 hover:shadow-sm border border-transparent hover:border-orange-100 dark:hover:border-orange-600 transition-all">
                                <div className="relative inline-block">
                                    <img src={client.avatar} className="w-12 h-12 rounded-full border-2 border-white dark:border-gray-600 shadow-sm mx-auto" alt={client.name} />
                                    <div className="absolute -top-1 -right-1 w-5 h-5 bg-orange-500 text-white rounded-full flex items-center justify-center text-xs font-bold border-2 border-white dark:border-gray-600">{i + 1}</div>
                                </div>
                                <p className="font-semibold text-xs mt-2 truncate text-gray-900 dark:text-gray-200">{client.name}</p>
                                <p className="text-[10px] text-orange-600 dark:text-orange-400 font-medium">{client.referrals} parrainages</p>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Top Spenders Card */}
                <div className="bg-gradient-to-br from-emerald-50 to-white dark:from-emerald-900 dark:to-gray-800 rounded-xl border border-emerald-100 dark:border-emerald-700 p-5 shadow-sm relative overflow-visible group">
                    <div className="absolute top-0 right-0 p-3 opacity-10"><DollarSign className="w-16 h-16 text-emerald-500 dark:text-emerald-400" /></div>
                    <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-4 flex items-center justify-between">
                        <span className="flex items-center gap-2">
                            <span className="bg-emerald-100 dark:bg-emerald-800 p-1.5 rounded-md text-emerald-600 dark:text-emerald-400"><Award className="w-4 h-4" /></span>
                            Elite Clients
                        </span>
                        {topSpenders.length > 3 && (
                            <button
                                type="button"
                                onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    console.log('Spenders clicked:', showAllSpenders);
                                    setShowAllSpenders(!showAllSpenders);
                                }}
                                className="text-xs font-medium text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300 transition-colors cursor-pointer z-10 relative"
                            >
                                {showAllSpenders ? 'Voir moins' : `Voir plus (${topSpenders.length})`}
                            </button>
                        )}
                    </h3>
                    <div className={`grid gap-3 ${showAllSpenders ? 'grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4' : 'grid-cols-1 sm:grid-cols-3'}`}>
                        {topSpenders.slice(0, showAllSpenders ? topSpenders.length : 3).map((client, i) => (
                            <div key={client.id} className="text-center p-3 rounded-lg bg-emerald-50/50 dark:bg-emerald-900/50 hover:bg-white dark:hover:bg-gray-700 hover:shadow-sm border border-transparent hover:border-emerald-100 dark:hover:border-emerald-600 transition-all">
                                <div className="relative inline-block">
                                    <img src={client.avatar} className="w-12 h-12 rounded-full border-2 border-white dark:border-gray-600 shadow-sm mx-auto" alt={client.name} />
                                    <div className="absolute -top-1 -right-1 w-5 h-5 bg-emerald-500 text-white rounded-full flex items-center justify-center text-xs font-bold border-2 border-white dark:border-gray-600">{i + 1}</div>
                                </div>
                                <p className="font-semibold text-xs mt-2 truncate text-gray-900 dark:text-gray-200">{client.name}</p>
                                <p className="text-[10px] text-emerald-700 dark:text-emerald-400 font-bold">{client.totalSpent.toLocaleString()} FCFA</p>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            {/* --- MAIN DATA SECTION --- */}
            {/* --- MAIN DATA SECTION --- */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex flex-col min-h-[500px]">

                {/* Toolbar */}
                {/* Toolbar */}
                <div className="p-4 border-b border-gray-100 dark:border-gray-700 flex flex-col md:flex-row gap-4 justify-between items-center bg-white dark:bg-gray-800 rounded-t-xl transition-colors duration-300">
                    <div className="relative w-full md:w-96">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                        <input
                            type="text"
                            placeholder="Rechercher un client..."
                            className="w-full pl-9 pr-4 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-emerald-500 outline-none transition-all dark:text-white dark:placeholder-gray-400"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>

                    <div className="flex gap-2 w-full md:w-auto overflow-x-auto">
                        <div className="flex items-center gap-2 px-3 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600">
                            <Filter className="w-4 h-4 text-gray-500 dark:text-gray-300" />
                            <select
                                className="bg-transparent text-sm text-gray-700 dark:text-gray-200 font-medium outline-none cursor-pointer"
                                value={statusFilter}
                                onChange={(e) => setStatusFilter(e.target.value)}
                            >
                                <option className="dark:bg-gray-800" value="all">Tout le monde</option>
                                <option className="dark:bg-gray-800" value="VIP">VIP Uniquement</option>
                                <option className="dark:bg-gray-800" value="Actif">Actifs</option>
                                <option className="dark:bg-gray-800" value="Inactif">Inactifs</option>
                            </select>
                        </div>

                        <div className="flex items-center gap-2 px-3 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600">
                            <ArrowUpDown className="w-4 h-4 text-gray-500 dark:text-gray-300" />
                            <select
                                className="bg-transparent text-sm text-gray-700 dark:text-gray-200 font-medium outline-none cursor-pointer"
                                value={sortBy}
                                onChange={(e) => setSortBy(e.target.value)}
                            >
                                <option className="dark:bg-gray-800" value="spent">Trier par: Dépenses</option>
                                <option className="dark:bg-gray-800" value="orders">Trier par: Commandes</option>
                                <option className="dark:bg-gray-800" value="referrals">Trier par: Parrainages</option>
                                <option className="dark:bg-gray-800" value="name">Trier par: Nom</option>
                            </select>
                        </div>
                    </div>
                </div>

                {/* Unified Table View */}
                <div className="overflow-x-auto flex-1 -mx-4 md:mx-0 px-4 md:px-0">
                    <table className="w-full text-left border-collapse min-w-[1000px]">
                        <thead className="bg-gray-50/50 dark:bg-gray-700/50 border-b border-gray-100 dark:border-gray-700 text-xs uppercase text-gray-400 dark:text-gray-500 font-semibold tracking-wider">
                            <tr>
                                <th className="px-6 py-4 w-12">
                                    <input
                                        type="checkbox"
                                        className="rounded border-gray-300 text-emerald-600 focus:ring-emerald-500 cursor-pointer w-4 h-4 dark:bg-gray-700 dark:border-gray-600"
                                        checked={selectedClients.length === currentClients.length && currentClients.length > 0}
                                        onChange={handleSelectAll}
                                    />
                                </th>
                                <th className="px-6 py-4">Client</th>
                                <th className="px-6 py-4">Statut</th>
                                <th className="px-6 py-4">Engagement</th>
                                <th className="px-6 py-4">Financier</th>
                                <th className="px-6 py-4">Dernière activité</th>
                                <th className="px-6 py-4 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-50">
                            {filteredClients.map(client => (
                                <tr key={client.id} className="hover:bg-gray-50/80 dark:hover:bg-gray-700/50 transition-colors group border-b last:border-0 border-gray-50 dark:border-gray-800">
                                    <td className="px-6 py-4">
                                        <input
                                            type="checkbox"
                                            className="rounded border-gray-300 text-emerald-600 focus:ring-emerald-500 cursor-pointer w-4 h-4 dark:bg-gray-700 dark:border-gray-600"
                                            checked={selectedClients.includes(client.id)}
                                            onChange={() => handleSelectOne(client.id)}
                                        />
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-3">
                                            <img src={client.avatar} alt="" className="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-700 object-cover" />
                                            <div>
                                                <h4 className="font-semibold text-gray-900 dark:text-gray-200 text-sm">{client.name}</h4>
                                                <div className="flex items-center gap-1 text-[11px] text-gray-500 dark:text-gray-400">
                                                    <MapPin className="w-3 h-3" /> {client.location}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border
                              ${client.status === 'VIP' ? 'bg-purple-50 text-purple-700 border-purple-100' :
                                                client.status === 'Actif' ? 'bg-green-50 text-green-700 border-green-100' :
                                                    client.status === 'Bloqué' ? 'bg-red-50 text-red-700 border-red-100' :
                                                        'bg-gray-50 text-gray-600 border-gray-100'}`}>
                                            {client.status}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-4">
                                            <div className="text-xs">
                                                <span className="block font-bold text-gray-900 dark:text-gray-200">{client.ordersCount}</span>
                                                <span className="text-gray-400">Achats</span>
                                            </div>
                                            <div className="w-px h-6 bg-gray-100 dark:bg-gray-700"></div>
                                            <div className="text-xs">
                                                <span className="block font-bold text-orange-600 dark:text-orange-400">{client.referrals}</span>
                                                <span className="text-gray-400">Invités</span>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className="font-bold text-emerald-700 bg-emerald-50 px-2 py-1 rounded-md text-sm">
                                            {client.totalSpent.toLocaleString()} FCFA
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 text-xs text-gray-500">
                                        {client.lastActive}
                                    </td>
                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end gap-2 opacity-100 transition-opacity">
                                            <button className="p-1.5 hover:bg-gray-100 rounded text-gray-400 hover:text-blue-600" title="Contacter"><Mail className="w-4 h-4" /></button>
                                            <button className="p-1.5 hover:bg-gray-100 rounded text-gray-400 hover:text-gray-900" title="Voir profil"><MoreHorizontal className="w-4 h-4" /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    {filteredClients.length === 0 && (
                        <div className="p-12 text-center text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800">
                            Aucun client ne correspond à votre recherche.
                        </div>
                    )}
                    {/* --- BULK ACTION BAR --- */}
                    {selectedClients.length > 0 && (
                        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 bg-gray-900 text-white px-6 py-3 rounded-xl shadow-2xl flex items-center gap-6 z-50 animation-slide-up">
                            <span className="font-medium">{selectedClients.length} clients sélectionnés</span>
                            <div className="h-4 w-px bg-gray-700"></div>
                            <button
                                onClick={handleBulkEmail}
                                className="flex items-center gap-2 hover:text-emerald-400 transition-colors"
                            >
                                <Mail className="w-4 h-4" />
                                <span className="text-sm font-semibold">Envoyer un email</span>
                            </button>
                            <button
                                onClick={() => setSelectedClients([])}
                                className="ml-4 p-1 hover:bg-gray-800 rounded-full"
                            >
                                <X className="w-4 h-4" />
                            </button>
                        </div>
                    )}
                </div>
            </div>

            {/* Email Modal */}
            {showEmailModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={() => setShowEmailModal(false)}>
                    <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl max-w-2xl w-full" onClick={(e) => e.stopPropagation()}>
                        <div className="bg-gradient-to-r from-blue-500 to-indigo-600 p-6 text-white rounded-t-2xl">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <Mail className="w-6 h-6" />
                                    <h2 className="text-2xl font-bold">Envoyer un email groupé</h2>
                                </div>
                                <button onClick={() => setShowEmailModal(false)} className="p-2 hover:bg-white/20 rounded-lg transition-colors">
                                    <X className="w-5 h-5" />
                                </button>
                            </div>
                            <p className="text-blue-100 mt-2">{selectedClients.length} destinataire(s) sélectionné(s)</p>
                        </div>

                        <div className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Objet</label>
                                <input
                                    type="text"
                                    value={emailSubject}
                                    onChange={(e) => setEmailSubject(e.target.value)}
                                    placeholder="Entrez l'objet de l'email"
                                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none dark:bg-gray-700 dark:text-white"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Message</label>
                                <textarea
                                    value={emailMessage}
                                    onChange={(e) => setEmailMessage(e.target.value)}
                                    placeholder="Rédigez votre message..."
                                    rows={8}
                                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none resize-none dark:bg-gray-700 dark:text-white"
                                />
                            </div>
                        </div>

                        <div className="border-t border-gray-200 dark:border-gray-700 p-4 flex justify-end gap-3">
                            <button
                                onClick={() => setShowEmailModal(false)}
                                className="px-4 py-2 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 rounded-lg font-medium transition-colors"
                            >
                                Annuler
                            </button>
                            <button
                                onClick={handleSendEmail}
                                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors flex items-center gap-2"
                            >
                                <Mail className="w-4 h-4" />
                                Envoyer
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div >
    );
};
