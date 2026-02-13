import React, { useState, useEffect } from 'react';
import { X, User, Mail, Shield, CheckCircle, Lock } from 'lucide-react';
import { User as UserType } from '../../types';

interface CreateUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (user: any) => void;
  initialData?: { name: string; email: string; role: string } | null;
}

export const CreateUserModal: React.FC<CreateUserModalProps> = ({ isOpen, onClose, onSubmit, initialData }) => {
  const [formData, setFormData] = useState<{
    nom: string;
    prenom: string;
    email: string;
    mot_de_passe: string;
    mot_de_passe_confirmation: string;
    role: string;
  }>({
    nom: '',
    prenom: '',
    email: '',
    mot_de_passe: '',
    mot_de_passe_confirmation: '',
    role: 'superadmin'
  });

  useEffect(() => {
    if (isOpen) {
      if (initialData) {
        const nameParts = initialData.name.split(' ');
        let roleCode = 'admin';
        if (initialData.role === 'Super Admin') roleCode = 'superadmin';
        else if (initialData.role === 'Scanner') roleCode = 'scanner';
        else if (initialData.role === 'Admin') roleCode = 'admin';
        
        setFormData({
          prenom: nameParts[0] || '',
          nom: nameParts.slice(1).join(' ') || '',
          email: initialData.email,
          mot_de_passe: '',
          mot_de_passe_confirmation: '',
          role: roleCode
        });
      } else {
        setFormData({ nom: '', prenom: '', email: '', mot_de_passe: '', mot_de_passe_confirmation: '', role: 'superadmin' });
      }
    }
  }, [isOpen, initialData]);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (formData.mot_de_passe !== formData.mot_de_passe_confirmation) {
      alert('Les mots de passe ne correspondent pas');
      return;
    }
    onSubmit(formData);
    onClose();
    if (!initialData) setFormData({ nom: '', prenom: '', email: '', mot_de_passe: '', mot_de_passe_confirmation: '', role: 'superadmin' });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
       <div 
        className="absolute inset-0 bg-gray-900/60 backdrop-blur-sm transition-opacity" 
        onClick={onClose}
      ></div>

      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md relative z-10 animate-in fade-in zoom-in-95 duration-200 overflow-y-auto max-h-[90vh]">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center">
          <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
            <Shield className="w-5 h-5 text-emerald-600" />
            {initialData ? "Modifier l'utilisateur" : "Nouvel Administrateur"}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 transition-colors">
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Prénom</label>
              <div className="relative group">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                <input
                  type="text"
                  required
                  className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 font-medium"
                  placeholder="Jean"
                  value={formData.prenom}
                  onChange={(e) => setFormData({ ...formData, prenom: e.target.value })}
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Nom</label>
              <div className="relative group">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                <input
                  type="text"
                  required
                  className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 font-medium"
                  placeholder="Dupont"
                  value={formData.nom}
                  onChange={(e) => setFormData({ ...formData, nom: e.target.value })}
                />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">Adresse Email</label>
            <div className="relative group">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
              <input
                type="email"
                required
                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 font-medium"
                placeholder="admin@eventmaster.com"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              />
            </div>
          </div>

          {!initialData && (
            <>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Mot de passe</label>
                <div className="relative group">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                  <input
                    type="password"
                    required
                    className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 font-medium"
                    placeholder="••••••••"
                    value={formData.mot_de_passe}
                    onChange={(e) => setFormData({ ...formData, mot_de_passe: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Confirmer le mot de passe</label>
                <div className="relative group">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                  <input
                    type="password"
                    required
                    className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 font-medium"
                    placeholder="••••••••"
                    value={formData.mot_de_passe_confirmation}
                    onChange={(e) => setFormData({ ...formData, mot_de_passe_confirmation: e.target.value })}
                  />
                </div>
              </div>
            </>
          )}

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-3">Rôle système</label>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <label className={`cursor-pointer border rounded-xl p-3 flex flex-col items-center gap-2 transition-all ${formData.role === 'superadmin' ? 'bg-purple-50 border-purple-500 ring-1 ring-purple-500' : 'bg-gray-50 border-gray-200 hover:bg-gray-100'}`}>
                <input type="radio" name="role" value="superadmin" className="hidden" checked={formData.role === 'superadmin'} onChange={() => setFormData({ ...formData, role: 'superadmin' })} />
                <span className="font-semibold text-sm text-gray-900">Super Admin</span>
                <span className="text-[10px] text-center text-gray-500 leading-tight hidden sm:block">Accès total</span>
              </label>
              <label className={`cursor-pointer border rounded-xl p-3 flex flex-col items-center gap-2 transition-all ${formData.role === 'admin' ? 'bg-emerald-50 border-emerald-500 ring-1 ring-emerald-500' : 'bg-gray-50 border-gray-200 hover:bg-gray-100'}`}>
                <input type="radio" name="role" value="admin" className="hidden" checked={formData.role === 'admin'} onChange={() => setFormData({ ...formData, role: 'admin' })} />
                <span className="font-semibold text-sm text-gray-900">Admin</span>
                <span className="text-[10px] text-center text-gray-500 leading-tight hidden sm:block">Gestion événements</span>
              </label>
              <label className={`cursor-pointer border rounded-xl p-3 flex flex-col items-center gap-2 transition-all ${formData.role === 'scanner' ? 'bg-amber-50 border-amber-500 ring-1 ring-amber-500' : 'bg-gray-50 border-gray-200 hover:bg-gray-100'}`}>
                <input type="radio" name="role" value="scanner" className="hidden" checked={formData.role === 'scanner'} onChange={() => setFormData({ ...formData, role: 'scanner' })} />
                <span className="font-semibold text-sm text-gray-900">Scanner</span>
                <span className="text-[10px] text-center text-gray-500 leading-tight hidden sm:block">Agent de contrôle</span>
              </label>
            </div>
          </div>

          <div className="pt-2">
            <button
              type="submit"
              className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl shadow-lg shadow-emerald-200 flex items-center justify-center gap-2 transition-all"
            >
              <CheckCircle className="w-5 h-5" />
              {initialData ? "Sauvegarder les modifications" : "Créer l'utilisateur"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
