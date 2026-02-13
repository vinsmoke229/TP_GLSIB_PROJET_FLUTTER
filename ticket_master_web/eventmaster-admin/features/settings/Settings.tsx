import React, { useState, useRef, useEffect } from 'react';
import { Settings as SettingsIcon, Bell, Lock, Globe, User, Shield, CreditCard, ChevronRight, Save, Upload } from 'lucide-react';

export const Settings: React.FC = () => {
   const [activeSection, setActiveSection] = useState('profile');
   const [profileImage, setProfileImage] = useState<string | null>(null);
   const [imageFile, setImageFile] = useState<File | null>(null);
   const [formData, setFormData] = useState({
      nom: '',
      prenom: '',
      email: ''
   });
   const [isLoading, setIsLoading] = useState(true);
   const [isSaving, setIsSaving] = useState(false);
   const fileInputRef = useRef<HTMLInputElement>(null);

   // Charger les données de l'administrateur au montage
   useEffect(() => {
      const fetchAdminData = async () => {
         try {
            const token = localStorage.getItem('authToken');
            const adminData = localStorage.getItem('administrateur');
            
            if (!adminData) {
               throw new Error('Données administrateur non trouvées');
            }
            const admin = JSON.parse(adminData);
            
            // Charger immédiatement les données depuis localStorage
            setFormData({
               nom: admin.nom || '',
               prenom: admin.prenom || '',
               email: admin.email || ''
            });
            
            // Charger l'image de profil depuis localStorage si elle existe
            if (admin.photo_profil) {
               const imageUrl = admin.photo_profil.startsWith('http') 
                  ? admin.photo_profil 
                  : `http://localhost:8000${admin.photo_profil}`;
               setProfileImage(imageUrl);
            }
            
            const adminId = admin.id_admin || admin.id;

            if (!adminId) {
               throw new Error('ID administrateur non trouvé');
            }
            const url = `http://localhost:8000/api/administrateurs/${adminId}/`;
            const response = await fetch(url, {
               headers: {
                  'Authorization': `Bearer ${token}`
               }
            });

            if (!response.ok) {
               console.error('Response status:', response.status);
               throw new Error('Erreur lors du chargement des données');
            }

            const data = await response.json();
            setFormData({
               nom: data.nom || '',
               prenom: data.prenom || '',
               email: data.email || ''
            });
            
            // Charger l'image de profil si elle existe
            if (data.photo_profil) {
               // Construire l'URL complète avec le domaine backend
               const imageUrl = data.photo_profil.startsWith('http') 
                  ? data.photo_profil 
                  : `http://localhost:8000${data.photo_profil}`;
               setProfileImage(imageUrl);
            }
         } catch (error) {
            console.error('Erreur:', error);
            alert('Erreur lors du chargement des données');
         } finally {
            setIsLoading(false);
         }
      };

      fetchAdminData();
   }, []);

   const sections = [
      { id: 'profile', label: 'Mon Profil', icon: User },
      { id: 'notifications', label: 'Notifications', icon: Bell },
      { id: 'security', label: 'Sécurité', icon: Shield },
      { id: 'preferences', label: 'Préférences', icon: Globe },
      { id: 'billing', label: 'Facturation', icon: CreditCard },
   ];

   const handleImageUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
      const file = event.target.files?.[0];
      if (file) {
         setImageFile(file);
         // Créer une URL de preview
         const previewUrl = URL.createObjectURL(file);
         setProfileImage(previewUrl);
      }
   };

   const handleSave = async () => {
      setIsSaving(true);
      try {
         const token = localStorage.getItem('authToken');
         const adminData = localStorage.getItem('administrateur');
         
         if (!adminData) {
            throw new Error('Données administrateur non trouvées');
         }

         const admin = JSON.parse(adminData);
         const adminId = admin.id_admin || admin.id;

         if (!adminId) {
            throw new Error('ID administrateur non trouvé');
         }

         const formDataToSend = new FormData();
         
         formDataToSend.append('nom', formData.nom);
         formDataToSend.append('prenom', formData.prenom);
         formDataToSend.append('email', formData.email);
         
         // Ajouter l'image seulement si un nouveau fichier a été sélectionné
         if (imageFile) {
            formDataToSend.append('photo', imageFile);
         }

         const response = await fetch(`http://localhost:8000/api/administrateurs/${adminId}/`, {
            method: 'PATCH',
            headers: {
               'Authorization': `Bearer ${token}`
            },
            body: formDataToSend
         });

         if (!response.ok) {
            throw new Error('Erreur lors de la sauvegarde');
         }

         const data = await response.json();
         alert('Modifications enregistrées avec succès !');
         
         // Mettre à jour l'image affichée avec l'URL du backend
         if (data.photo_profil) {
            const imageUrl = data.photo_profil.startsWith('http') 
               ? data.photo_profil 
               : `http://localhost:8000${data.photo_profil}`;
            setProfileImage(imageUrl);
         }
         setImageFile(null);
      } catch (error) {
         console.error('Erreur:', error);
         alert('Erreur lors de la sauvegarde des modifications');
      } finally {
         setIsSaving(false);
      }
   };

   return (
      <div className="space-y-6">
         {/* Header */}
         <div className="flex items-center justify-between">
            <div>
               <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-gray-700 to-gray-900 flex items-center justify-center">
                     <SettingsIcon className="w-6 h-6 text-white" />
                  </div>
                  Paramètres
               </h1>
               <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
                  Configurez votre compte et vos préférences
               </p>
            </div>
         </div>

         <div className="flex flex-col md:flex-row gap-6 h-[calc(100vh-140px)]">
         {/* Settings Sidebar */}
         <div className="w-full md:w-64 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 h-fit overflow-hidden shrink-0">
            <div className="p-4 border-b border-gray-100 dark:border-gray-700">
               <h2 className="font-bold text-gray-900 dark:text-white flex items-center gap-2">
                  <SettingsIcon className="w-5 h-5 text-emerald-600" />
                  Paramètres
               </h2>
            </div>
            <nav className="p-2 space-y-1">
               {sections.map((section) => (
                  <button
                     key={section.id}
                     onClick={() => setActiveSection(section.id)}
                     className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-lg transition-all ${activeSection === section.id
                        ? 'bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400'
                        : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700/50'
                        }`}
                  >
                     <section.icon className={`w-4 h-4 ${activeSection === section.id ? 'text-emerald-600' : 'text-gray-400'}`} />
                     {section.label}
                     {activeSection === section.id && <ChevronRight className="w-4 h-4 ml-auto" />}
                  </button>
               ))}
            </nav>
         </div>

         {/* Settings Content */}
         <div className="flex-1 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-y-auto">
            {activeSection === 'profile' && (
               <div className="p-6 md:p-8 space-y-8 animate-in fade-in slide-in-from-right-4 duration-300">
                  <div>
                     <h3 className="text-xl font-bold text-gray-900 dark:text-white">Informations Personnelles</h3>
                     <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Mettez à jour votre photo et vos détails personnels.</p>
                  </div>

                  {isLoading ? (
                     <div className="flex items-center justify-center py-12">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-600"></div>
                     </div>
                  ) : (
                  <>

                  <div className="flex items-center gap-6 pb-6 border-b border-gray-100 dark:border-gray-700">
                     <div className="relative group">
                        <div className="w-24 h-24 rounded-full bg-emerald-100 dark:bg-emerald-900/50 flex items-center justify-center text-3xl font-bold text-emerald-700 dark:text-emerald-400 ring-4 ring-white dark:ring-gray-800 overflow-hidden">
                           {profileImage ? (
                              <img src={profileImage} alt="Profile" className="w-full h-full object-cover" />
                           ) : (
                              "AD"
                           )}
                        </div>
                        <input
                           type="file"
                           ref={fileInputRef}
                           onChange={handleImageUpload}
                           className="hidden"
                           accept="image/*"
                        />
                        <button
                           onClick={() => fileInputRef.current?.click()}
                           className="absolute bottom-0 right-0 p-1.5 bg-gray-900 dark:bg-emerald-600 text-white rounded-full shadow border-2 border-white dark:border-gray-800 hover:bg-black dark:hover:bg-emerald-700 transition-colors"
                        >
                           <Upload className="w-3 h-3" />
                        </button>
                     </div>
                     <div>
                        <h4 className="font-semibold text-gray-900 dark:text-white">Photo de profil</h4>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 max-w-xs">Accepte JPG, GIF ou PNG. Taille max. 800Ko.</p>
                     </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                     <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-700 dark:text-gray-300">Prénom</label>
                        <input 
                           type="text" 
                           value={formData.prenom} 
                           onChange={(e) => setFormData({ ...formData, prenom: e.target.value })}
                           className="w-full px-4 py-2.5 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-emerald-500 outline-none transition-all placeholder-gray-400" 
                        />
                     </div>
                     <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-700 dark:text-gray-300">Nom</label>
                        <input 
                           type="text" 
                           value={formData.nom} 
                           onChange={(e) => setFormData({ ...formData, nom: e.target.value })}
                           className="w-full px-4 py-2.5 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-emerald-500 outline-none transition-all placeholder-gray-400" 
                        />
                     </div>
                     <div className="space-y-2 md:col-span-2">
                        <label className="text-sm font-medium text-gray-700 dark:text-gray-300">Email</label>
                        <input 
                           type="email" 
                           value={formData.email} 
                           onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                           className="w-full px-4 py-2.5 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-emerald-500 outline-none transition-all placeholder-gray-400" 
                        />
                     </div>
                  </div>

                  <div className="flex justify-end pt-4">
                     <button 
                        onClick={handleSave}
                        disabled={isSaving}
                        className="flex items-center gap-2 px-6 py-2.5 bg-emerald-600 text-white rounded-xl font-medium shadow-lg shadow-emerald-500/20 hover:bg-emerald-700 hover:shadow-emerald-500/30 transition-all active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
                     >
                        <Save className="w-4 h-4" />
                        {isSaving ? 'Enregistrement...' : 'Enregistrer les modifications'}
                     </button>
                  </div>
                  </>
                  )}
               </div>
            )}

            {activeSection === 'notifications' && (
               <div className="p-6 md:p-8 space-y-8 animate-in fade-in slide-in-from-right-4 duration-300">
                  <div>
                     <h3 className="text-xl font-bold text-gray-900 dark:text-white">Préférences de Notification</h3>
                     <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Choisissez comment et quand vous souhaitez être notifié.</p>
                  </div>

                  <div className="space-y-6">
                     <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                        <div>
                           <h4 className="font-medium text-gray-900 dark:text-white">Alertes de vente</h4>
                           <p className="text-xs text-gray-500 dark:text-gray-400">Recevoir une notif à chaque billet vendu.</p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                           <input type="checkbox" defaultChecked className="sr-only peer" />
                           <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-emerald-300 dark:peer-focus:ring-emerald-800 rounded-full peer dark:bg-gray-600 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-emerald-600"></div>
                        </label>
                     </div>
                     <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                        <div>
                           <h4 className="font-medium text-gray-900 dark:text-white">Rapport Hebdomadaire</h4>
                           <p className="text-xs text-gray-500 dark:text-gray-400">Résumé de vos performances par email.</p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                           <input type="checkbox" defaultChecked className="sr-only peer" />
                           <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-emerald-300 dark:peer-focus:ring-emerald-800 rounded-full peer dark:bg-gray-600 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-emerald-600"></div>
                        </label>
                     </div>
                     <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                        <div>
                           <h4 className="font-medium text-gray-900 dark:text-white">Newsletters Produit</h4>
                           <p className="text-xs text-gray-500 dark:text-gray-400">Nouveautés et mises à jour EventMaster.</p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                           <input type="checkbox" className="sr-only peer" />
                           <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-emerald-300 dark:peer-focus:ring-emerald-800 rounded-full peer dark:bg-gray-600 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-emerald-600"></div>
                        </label>
                     </div>
                  </div>
               </div>
            )}

            {activeSection !== 'profile' && activeSection !== 'notifications' && (
               <div className="flex flex-col items-center justify-center h-full text-center p-8">
                  <div className="w-20 h-20 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center mb-4">
                     <SettingsIcon className="w-10 h-10 text-gray-400" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 dark:text-white">Section en construction</h3>
                  <p className="text-gray-500 dark:text-gray-400 mt-2 max-w-sm">Cette section des paramètres sera disponible dans la prochaine mise à jour.</p>
               </div>
            )}
         </div>
      </div>
      </div>
   );
};
