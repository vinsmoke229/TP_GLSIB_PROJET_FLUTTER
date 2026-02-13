import React, { useState, useEffect } from 'react';
import { Users as UsersIcon, Shield, CheckCircle2, AlertCircle, ScanLine, Crown, Headphones, Edit2, Power, Ban, ArrowLeft, ArrowRight, Plus, Search, Filter, Loader2, Trash2, MoreVertical } from 'lucide-react';
import { CreateUserModal } from './CreateUserModal';

interface User {
    id: number;
    name: string;
    email: string;
    role: string;
    status: 'Actif' | 'Inactif' | 'Suspendu';
    avatar: string;
    color: string;
}

const RoleBadge = ({ role }: { role: string }) => {
    switch (role) {
        case 'Super Admin': return <span className="inline-flex items-center gap-1 bg-purple-50 text-purple-700 px-2.5 py-1 rounded-md text-xs font-bold border border-purple-100"><Shield className="w-3 h-3" /> {role}</span>;
        case 'Admin': return <span className="inline-flex items-center gap-1 bg-emerald-50 text-emerald-700 px-2.5 py-1 rounded-md text-xs font-medium border border-emerald-100"><Crown className="w-3 h-3" /> {role}</span>;
        case 'Scanner': return <span className="inline-flex items-center gap-1 bg-amber-50 text-amber-700 px-2.5 py-1 rounded-md text-xs font-medium border border-amber-100"><ScanLine className="w-3 h-3" /> {role}</span>;
        default: return <span className="inline-flex items-center gap-1 bg-gray-50 text-gray-700 px-2.5 py-1 rounded-md text-xs font-medium border border-gray-100">{role}</span>;
    }
};

const StatusBadge = ({ status }: { status: string }) => {
    switch (status) {
        case 'Actif': return <span className="inline-flex items-center gap-1.5 bg-green-50 text-green-700 px-2.5 py-1 rounded-full text-xs font-semibold ring-1 ring-green-600/10"><div className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse" /> Actif</span>;
        case 'Inactif': return <span className="inline-flex items-center gap-1 bg-red-50 text-red-700 px-2.5 py-1 rounded-full text-xs font-medium border border-red-100"><Ban className="w-3 h-3" /> Inactif</span>;
        default: return <span className="inline-flex items-center gap-1 bg-gray-100 text-gray-700 px-2.5 py-1 rounded-full text-xs font-medium">{status}</span>;
    }
};

export const Users: React.FC = () => {
    const [users, setUsers] = useState<User[]>([]);
    const [userToEdit, setUserToEdit] = useState<User | null>(null);
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [roleFilter, setRoleFilter] = useState('all');
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    // Fonction pour charger les utilisateurs depuis l'API
    const fetchUsers = async () => {
        setIsLoading(true);
        setError(null);
        try {
            const token = localStorage.getItem('authToken');
            const response = await fetch('http://localhost:8000/api/administrateurs/', {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error('Erreur lors du chargement des utilisateurs');
            }

            const data = await response.json();
        
            // L'API retourne un objet paginé avec { count, next, previous, results }
            const transformedUsers: User[] = (data.results || []).map((admin: any, index: number) => {
                // Mapping des rôles de l'API vers les noms d'affichage
                let roleName = 'Admin';
                if (admin.role === 'superadmin' || admin.role === 'Super admin') roleName = 'Super Admin';
                else if (admin.role === 'scanner' || admin.role === 'Scanner') roleName = 'Scanner';
                else if (admin.role === 'admin' || admin.role === 'Admin') roleName = 'Admin';
                
                // Mapping du statut de l'API vers les noms d'affichage
                let statusName: 'Actif' | 'Inactif' = 'Actif';
                const apiStatus = (admin.statut || admin.status || '').toLowerCase();
                if (apiStatus === 'actif' || apiStatus === 'active') {
                    statusName = 'Actif';
                } else if (apiStatus === 'inactif' || apiStatus === 'inactive') {
                    statusName = 'Inactif';
                }
                
                return {
                    id: admin.id_admin,
                    name: `${admin.prenom || ''} ${admin.nom || ''}`.trim(),
                    email: admin.email || '',
                    role: roleName,
                    status: statusName,
                    avatar: admin.prenom ? admin.prenom.charAt(0).toUpperCase() : 'A',
                    color: 'bg-blue-100 text-blue-600'
                };
            });

            setUsers(transformedUsers);
        } catch (err) {
            console.error('Erreur:', err); 
            setError('Impossible de charger les utilisateurs');
        } finally {
            setIsLoading(false);
        }
    };
    
    // Charger les utilisateurs au montage du composant
    useEffect(() => {
        fetchUsers();
    }, []);

    const filteredUsers = users.filter(user => {
        const matchesSearch = user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.email.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesRole = roleFilter === 'all' || user.role === roleFilter;
        return matchesSearch && matchesRole;
    });

    const toggleStatus = async (id: number) => {
        const user = users.find(u => u.id === id);
        if (!user) return;

        const isActive = user.status === 'Actif';
        const action = isActive ? 'desactiver' : 'activer';
        
        try {
            const token = localStorage.getItem('authToken');
            const response = await fetch(`http://localhost:8000/api/administrateurs/${id}/${action}/`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`Erreur lors de la ${isActive ? 'désactivation' : 'réactivation'} de l'utilisateur`);
            }

            // Recharger la liste des utilisateurs
            await fetchUsers();
        } catch (err) {
            console.error('Erreur:', err);
            alert(err instanceof Error ? err.message : `Erreur lors de la ${isActive ? 'désactivation' : 'réactivation'} de l'utilisateur`);
        }
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Êtes-vous sûr de vouloir supprimer cet utilisateur ?')) {
            return;
        }

        try {
            const token = localStorage.getItem('authToken');
            const response = await fetch(`http://localhost:8000/api/administrateurs/${id}/`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });

            if (!response.ok) {
                throw new Error('Erreur lors de la suppression de l\'utilisateur');
            }

            // Recharger la liste des utilisateurs
            await fetchUsers();
        } catch (err) {
            console.error('Erreur lors de la suppression:', err);
            alert(err instanceof Error ? err.message : 'Erreur lors de la suppression de l\'utilisateur');
        }
    };

    const handleEdit = (id: number) => {
        const user = users.find(u => u.id === id);
        if (user) {
            setUserToEdit(user);
            setIsCreateModalOpen(true);
        }
    };

    const handleSaveUser = async (userData: any) => {
        if (userToEdit) {
            // Edit mode - Mise à jour via API
            try {
                const token = localStorage.getItem('authToken');
                // Préparer les données pour l'API (sans les mots de passe en mode édition)
                const updateData: any = {
                    nom: userData.nom,
                    prenom: userData.prenom,
                    email: userData.email,
                    role: userData.role
                };

                const response = await fetch(`http://localhost:8000/api/administrateurs/${userToEdit.id}/`, {
                    method: 'PUT',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(updateData),
                });

                if (!response.ok) {
                    const errorData = await response.json();
                    throw new Error(errorData.message || 'Erreur lors de la mise à jour de l\'utilisateur');
                }

                // Recharger la liste des utilisateurs
                await fetchUsers();
                setUserToEdit(null);
                setIsCreateModalOpen(false);
            } catch (err) {
                console.error('Erreur lors de la mise à jour:', err);
                alert(err instanceof Error ? err.message : 'Erreur lors de la mise à jour de l\'utilisateur');
            }
        } else {
            // Create mode - Appel à l'API
            try {
                const token = localStorage.getItem('authToken');
                const response = await fetch('http://localhost:8000/api/administrateurs/', {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(userData),
                });

                if (!response.ok) {
                    const errorData = await response.json();
                    throw new Error(errorData.message || 'Erreur lors de la création de l\'utilisateur');
                }

                // Recharger la liste des utilisateurs
                await fetchUsers();
                setIsCreateModalOpen(false);
            } catch (err) {
                console.error('Erreur lors de la création:', err);
                alert(err instanceof Error ? err.message : 'Erreur lors de la création de l\'utilisateur');
            }
        }
    };

    return (
        <div className="space-y-6 animation-fade-in pb-10">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-500 to-fuchsia-600 flex items-center justify-center">
                            <UsersIcon className="w-6 h-6 text-white" />
                        </div>
                        Gestion des Utilisateurs
                    </h1>
                    <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
                        Gérez les accès et les rôles de votre équipe
                    </p>
                </div>
                <button
                    onClick={() => { setUserToEdit(null); setIsCreateModalOpen(true); }}
                    className="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2.5 rounded-xl text-sm font-semibold flex items-center gap-2 transition-colors shadow-lg shadow-emerald-600/20 active:scale-95"
                >
                    <Plus className="w-4 h-4" />
                    Ajouter un utilisateur
                </button>
            </div>

            <CreateUserModal
                isOpen={isCreateModalOpen}
                onClose={() => { setIsCreateModalOpen(false); setUserToEdit(null); }}
                onSubmit={handleSaveUser}
                initialData={userToEdit}
            />

            <div className="flex flex-col md:flex-row gap-4 justify-between items-center bg-white dark:bg-gray-800 p-4 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
                <div className="relative w-full md:w-96">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Rechercher un utilisateur (nom, email)..."
                        className="w-full pl-9 pr-4 py-2.5 bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 outline-none transition-all text-gray-700 dark:text-gray-200 placeholder-gray-400"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>

                <div className="flex items-center gap-3 w-full md:w-auto">
                    <div className="relative w-full md:w-auto">
                        <Filter className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                        <select
                            className="w-full md:w-auto appearance-none pl-9 pr-8 py-2.5 bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg text-sm text-gray-700 dark:text-gray-200 font-medium outline-none focus:ring-2 focus:ring-emerald-500 cursor-pointer"
                            value={roleFilter}
                            onChange={(e) => setRoleFilter(e.target.value)}
                        >
                            <option value="all">Tous les rôles</option>
                            <option value="Super Admin">Super Admin</option>
                            <option value="Admin">Admin</option>
                            <option value="Scanner">Scanner</option>
                        </select>
                    </div>
                </div>
            </div>

            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
                {isLoading ? (
                    <div className="flex items-center justify-center py-16">
                        <div className="text-center">
                            <Loader2 className="w-8 h-8 text-emerald-500 animate-spin mx-auto mb-3" />
                            <p className="text-sm text-gray-500 dark:text-gray-400">Chargement des utilisateurs...</p>
                        </div>
                    </div>
                ) : error ? (
                    <div className="flex items-center justify-center py-16">
                        <div className="text-center">
                            <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-3" />
                            <p className="text-sm text-red-600 dark:text-red-400 font-medium">{error}</p>
                            <button
                                onClick={fetchUsers}
                                className="mt-4 px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm hover:bg-emerald-700 transition-colors"
                            >
                                Réessayer
                            </button>
                        </div>
                    </div>
                ) : (
                    <div className="overflow-x-auto -mx-4 md:mx-0 px-4 md:px-0">
                        <table className="w-full text-left border-collapse min-w-[800px]">
                            <thead>
                                <tr className="bg-gray-50/50 dark:bg-gray-700/50 border-b border-gray-100 dark:border-gray-700 text-xs uppercase text-gray-500 dark:text-gray-400 font-semibold tracking-wider">
                                    <th className="px-6 py-4">Utilisateur</th>
                                    <th className="px-6 py-4">Rôle</th>
                                    <th className="px-6 py-4">Statut</th>
                                    <th className="px-6 py-4 text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50 dark:divide-gray-700">
                            {filteredUsers.map(user => (
                                <tr key={user.id} className={`transition-colors ${user.status === 'Suspendu' ? 'bg-gray-50/50 dark:bg-gray-800/50' : 'hover:bg-gray-50 dark:hover:bg-gray-700/50'}`}>
                                    <td className="px-6 py-3.5">
                                        <div className="flex items-center gap-3">
                                            <div className={`w-9 h-9 rounded-full flex items-center justify-center font-bold text-sm ${user.color} ${user.status === 'Suspendu' ? 'grayscale opacity-70' : ''}`}>
                                                {user.avatar}
                                            </div>
                                            <div>
                                                <div className={`font-medium ${user.status === 'Suspendu' ? 'text-gray-500 dark:text-gray-400' : 'text-gray-900 dark:text-white'}`}>{user.name}</div>
                                                <div className="text-xs text-gray-500 dark:text-gray-400 font-mono">{user.email}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-3.5">
                                        <RoleBadge role={user.role} />
                                    </td>
                                    <td className="px-6 py-3.5">
                                        <StatusBadge status={user.status} />
                                    </td>
                                    <td className="px-6 py-3.5 text-center">
                                        <div className="flex items-center justify-center gap-2">
                                            {/* Bouton Éditer */}
                                            <button
                                                onClick={() => handleEdit(user.id)}
                                                className="p-2 text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"
                                                title="Éditer"
                                            >
                                                <Edit2 className="w-4 h-4" />
                                            </button>

                                            {/* Bouton Désactiver/Activer */}
                                            <button
                                                onClick={() => toggleStatus(user.id)}
                                                className={`p-2 rounded-lg transition-colors ${user.status === 'Actif'
                                                    ? 'text-gray-400 dark:text-gray-500 hover:text-orange-600 dark:hover:text-orange-400 hover:bg-orange-50 dark:hover:bg-orange-900/30'
                                                    : 'text-green-600 dark:text-green-400 hover:bg-green-50 dark:hover:bg-green-900/30'
                                                    }`}
                                                title={user.status === 'Actif' ? 'Désactiver' : 'Réactiver'}
                                            >
                                                <Power className="w-4 h-4" />
                                            </button>

                                            {/* Bouton Supprimer */}
                                            <button
                                                onClick={() => handleDelete(user.id)}
                                                className="p-2 text-gray-400 dark:text-gray-500 hover:text-red-600 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg transition-colors"
                                                title="Supprimer"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
                )}

                {/* Pagination Footer */}
                {!isLoading && !error && (
                <div className="px-6 py-4 border-t border-gray-100 dark:border-gray-700 bg-gray-50/30 dark:bg-gray-800/30 flex justify-between items-center">
                    <span className="text-xs text-gray-500 dark:text-gray-400 font-medium">Affichage de {filteredUsers.length} utilisateurs</span>
                    <div className="flex gap-2">
                        <button
                            className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-gray-400 dark:text-gray-600 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg cursor-not-allowed opacity-60"
                            disabled
                        >
                            <ArrowLeft className="w-3 h-3" /> Précédent
                        </button>
                        <button
                            className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-gray-700 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg transition-colors"
                        >
                            Suivant <ArrowRight className="w-3 h-3" />
                        </button>
                    </div>
                </div>
                )}
            </div>
        </div>
    );
};
