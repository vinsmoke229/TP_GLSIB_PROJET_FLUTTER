import React, { useState } from 'react';
import { X, Calendar, MapPin, Type, FileText, Image as ImageIcon, Sparkles, Eye, Music, Mic, Users, Trophy, LayoutGrid, RefreshCw, Upload } from 'lucide-react';
import { Event } from '../../types';

interface CreateEventModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
  event?: Event | null;
}

const EVENT_TYPES = [
  { id: 'Concert', icon: Music, label: 'Concert' },
  { id: 'Conférence', icon: Mic, label: 'Conférence' },
  { id: 'Festival', icon: Users, label: 'Festival' },
  { id: 'Sport', icon: Trophy, label: 'Sport' },
  { id: 'Autre', icon: LayoutGrid, label: 'Autre' },
];

export const CreateEventModal: React.FC<CreateEventModalProps> = ({ isOpen, onClose, onSuccess, event }) => {
  const [formData, setFormData] = useState({
    title: event?.title || '',
    date: event?.date || '',
    startTime: event?.startTime || '',
    endTime: event?.endTime || '',
    location: event?.location || '',
    description: event?.description || '',
    eventType: event?.eventType || 'Concert'
  });

  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string>(event?.imageUrl || 'https://via.placeholder.com/800x400');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Mettre à jour le formulaire quand l'événement change
  React.useEffect(() => {
    if (event) {
      setFormData({
        title: event.title || '',
        date: event.date || '',
        startTime: event.startTime || '',
        endTime: event.endTime || '',
        location: event.location || '',
        description: event.description || '',
        eventType: event.eventType || 'Concert'
      });
      setImagePreview(event.imageUrl || 'https://via.placeholder.com/800x400');
      setImageFile(null);
    } else if (!isOpen) {
      setFormData({
        title: '',
        date: '',
        startTime: '',
        endTime: '',
        location: '',
        description: '',
        eventType: 'Concert'
      });
      setImagePreview('https://via.placeholder.com/800x400');
      setImageFile(null);
    }
  }, [event, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      const token = localStorage.getItem('authToken');
      
      // Utiliser FormData pour l'upload de fichier
      const formDataToSend = new FormData();
      formDataToSend.append('titre_evenement', formData.title);
      formDataToSend.append('date', formData.date);
      formDataToSend.append('heure_debut', formData.startTime);
      formDataToSend.append('heure_fin', formData.endTime);
      formDataToSend.append('lieu', formData.location);
      formDataToSend.append('type_evenement', formData.eventType);
      
      // Ajouter l'image seulement si un fichier a été sélectionné
      if (imageFile) {
        formDataToSend.append('image', imageFile);
      }

      let response;
      if (event) {
        // Mode édition : PUT
        response = await fetch(`http://localhost:8000/api/evenements/${event.id}/`, {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${token}`
            // NE PAS mettre Content-Type, le navigateur le gère automatiquement avec FormData
          },
          body: formDataToSend
        });
      } else {
        // Mode création : POST
        if (!imageFile) {
          alert('Veuillez sélectionner une image');
          setIsSubmitting(false);
          return;
        }
        response = await fetch('http://localhost:8000/api/evenements/', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`
            // NE PAS mettre Content-Type, le navigateur le gère automatiquement avec FormData
          },
          body: formDataToSend
        });
      }

      if (!response.ok) {
        throw new Error(event ? 'Erreur lors de la modification de l\'événement' : 'Erreur lors de la création de l\'événement');
      }

      // Reset form
      setFormData({
        title: '',
        date: '',
        startTime: '',
        endTime: '',
        location: '',
        description: '',
        eventType: 'Concert'
      });
      setImageFile(null);
      setImagePreview('https://via.placeholder.com/800x400');

      onClose();
      if (onSuccess) onSuccess();
    } catch (error) {
      console.error('Erreur:', error);
      alert('Erreur lors de la création de l\'événement');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      // Créer une URL de preview pour afficher l'image sélectionnée
      const previewUrl = URL.createObjectURL(file);
      setImagePreview(previewUrl);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-gray-900/60 backdrop-blur-sm transition-opacity"
        onClick={onClose}
      ></div>

      {/* Modal Container */}
      <div className="bg-white dark:bg-gray-800 w-full max-w-full md:max-w-2xl lg:max-w-4xl xl:max-w-5xl h-[100dvh] md:h-auto md:max-h-[90vh] md:rounded-2xl md:shadow-2xl overflow-hidden relative z-10 flex flex-col md:flex-row">

        {/* Left Side: Form */}
        <div className="flex-1 flex flex-col min-h-0 h-full md:h-auto overflow-hidden">
          <div className="p-4 sm:p-6 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center bg-white dark:bg-gray-800 flex-shrink-0 z-20">
            <div>
              <h2 className="text-xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-emerald-500" />
                {event ? 'Modifier l\'événement' : 'Créer un événement'}
              </h2>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Configurez les détails principaux</p>
            </div>
            <button onClick={onClose} className="text-gray-400 hover:text-gray-600 hover:bg-gray-100 p-2 rounded-full transition-all md:hidden">
              <X className="w-6 h-6" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-4 sm:p-6 md:p-8 overscroll-contain">
            <form id="create-event-form" onSubmit={handleSubmit} className="space-y-4 sm:space-y-6">

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1.5">Titre de l'événement</label>
                  <div className="relative group">
                    <FileText className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                    <input
                      type="text"
                      required
                      className="w-full pl-10 pr-4 py-3 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-xl focus:bg-white dark:focus:bg-gray-600 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 text-gray-900 dark:text-white font-medium"
                      placeholder="Ex: Summer Vibes Festival 2024"
                      value={formData.title}
                      onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1.5">Date</label>
                    <div className="relative group">
                      <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                      <input
                        type="date"
                        required
                        className="w-full pl-10 pr-4 py-3 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-xl focus:bg-white dark:focus:bg-gray-600 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all font-medium text-gray-600 dark:text-gray-200"
                        value={formData.date}
                        onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1.5">Lieu</label>
                    <div className="relative group">
                      <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-emerald-500 transition-colors" />
                      <input
                        type="text"
                        required
                        className="w-full pl-10 pr-4 py-3 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-xl focus:bg-white dark:focus:bg-gray-600 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all placeholder-gray-400 text-gray-900 dark:text-white font-medium"
                        placeholder="Ex: Paris, France"
                        value={formData.location}
                        onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                      />
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1.5">Début</label>
                      <div className="relative group">
                         <input
                          type="time"
                          className="w-full pl-4 pr-4 py-3 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-xl focus:bg-white dark:focus:bg-gray-600 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all font-medium text-gray-600 dark:text-gray-200"
                          value={formData.startTime}
                          onChange={(e) => setFormData({ ...formData, startTime: e.target.value })}
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1.5">Fin</label>
                      <div className="relative group">
                        <input
                          type="time"
                          className="w-full pl-4 pr-4 py-3 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-xl focus:bg-white dark:focus:bg-gray-600 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all font-medium text-gray-600 dark:text-gray-200"
                          value={formData.endTime}
                          onChange={(e) => setFormData({ ...formData, endTime: e.target.value })}
                        />
                      </div>
                    </div>
                  </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Type d'événement</label>
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                    {EVENT_TYPES.map((type) => {
                      const Icon = type.icon;
                      const isSelected = formData.eventType === type.id;
                      return (
                        <button
                          key={type.id}
                          type="button"
                          onClick={() => setFormData({ ...formData, eventType: type.id })}
                          className={`flex flex-col items-center justify-center gap-2 p-3 rounded-xl border transition-all duration-200 ${isSelected
                            ? 'bg-emerald-50 dark:bg-emerald-900/30 border-emerald-500 text-emerald-700 dark:text-emerald-400 ring-1 ring-emerald-500 shadow-sm'
                            : 'bg-white dark:bg-gray-700 border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600 hover:border-gray-300'
                            }`}
                        >
                          <Icon className={`w-6 h-6 ${isSelected ? 'text-emerald-600 dark:text-emerald-400' : 'text-gray-400'}`} />
                          <span className="text-xs font-medium">{type.label}</span>
                        </button>
                      );
                    })}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1.5">Image de couverture</label>
                  <div className="flex flex-col gap-3">
                    {/* File Upload */}
                    <div className="relative group">
                      <input
                        type="file"
                        accept="image/*"
                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                        onChange={handleImageUpload}
                        required={!event}
                      />
                      <div className="flex items-center justify-center gap-2 p-4 bg-gray-50 dark:bg-gray-700 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-xl text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-600 hover:border-emerald-500 transition-colors cursor-pointer">
                        <Upload className="w-5 h-5" />
                        <span className="text-sm font-medium">
                          {imageFile ? imageFile.name : event ? 'Changer l\'image (optionnel)' : 'Télécharger une image *'}
                        </span>
                      </div>
                    </div>
                    {imageFile && (
                      <p className="text-xs text-emerald-600 dark:text-emerald-400 ml-1 flex items-center gap-1">
                        <span className="w-2 h-2 bg-emerald-500 rounded-full"></span>
                        Image sélectionnée : {imageFile.name}
                      </p>
                    )}
                  </div>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-2 ml-1">
                    Formats acceptés : JPG, PNG, GIF (max 10MB)
                  </p>
                </div>
              </div>
            </form>
          </div>

          <div className="p-4 sm:p-6 border-t border-gray-100 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50 flex flex-col sm:flex-row justify-end gap-2 sm:gap-3 flex-shrink-0">
            <button
              type="button"
              onClick={onClose}
              disabled={isSubmitting}
              className="px-5 py-2.5 text-sm font-semibold text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-600 rounded-xl transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Annuler
            </button>
            <button
              type="submit"
              form="create-event-form"
              disabled={isSubmitting}
              className="px-5 py-2.5 text-sm font-semibold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl shadow-md shadow-emerald-200 dark:shadow-none transition-all transform active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-emerald-600"
            >
              {isSubmitting 
                ? (event ? 'Modification...' : 'Création...') 
                : (event ? 'Modifier l\'événement' : 'Créer l\'événement')
              }
            </button>
          </div>
        </div>

        {/* Right Side: Live Preview (Hidden on mobile) */}
        <div className="hidden md:flex md:w-[400px] bg-gray-900 flex-col relative overflow-hidden">
          {/* Background decorative elements */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-emerald-500 rounded-bl-full opacity-10 blur-3xl"></div>
          <div className="absolute bottom-0 left-0 w-64 h-64 bg-blue-500 rounded-tr-full opacity-10 blur-3xl"></div>

          <div className="relative z-10 flex-1 flex flex-col p-8">
            <div className="flex justify-between items-start mb-8 text-white/80">
              <div>
                <h3 className="text-lg font-bold text-white flex items-center gap-2">
                  <Eye className="w-5 h-5" />
                  Aperçu Live
                </h3>
                <p className="text-sm opacity-70">Voici à quoi ressemblera votre carte.</p>
              </div>
              <button onClick={onClose} className="text-white/50 hover:text-white transition-colors">
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="flex-1 flex items-center justify-center">
              {/* Card Preview Mockup */}
              <div className="w-full bg-white rounded-2xl overflow-hidden shadow-2xl transform transition-all duration-500 hover:scale-[1.02]">
                <div className="h-40 bg-gray-200 relative overflow-hidden group">
                  <img
                    src={imagePreview}
                    alt="Preview"
                    className="w-full h-full object-cover"
                    onError={(e) => { (e.target as HTMLImageElement).src = 'https://via.placeholder.com/800x400?text=Aperçu+Image'; }}
                  />
                  <div className="absolute top-3 right-3">
                    <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-yellow-500 text-white shadow-sm">
                      Brouillon
                    </span>
                  </div>
                  <div className="absolute bottom-3 left-3">
                    <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-white/90 text-gray-800 backdrop-blur-md shadow-sm">
                      {formData.eventType}
                    </span>
                  </div>
                </div>

                <div className="p-5">
                  <h3 className="font-bold text-lg text-gray-900 mb-2 truncate leading-tight">
                    {formData.title || 'Titre de l\'événement'}
                  </h3>

                  <div className="space-y-2 text-sm text-gray-600 mb-4">
                    <div className="flex items-center gap-2">
                      <Calendar className="w-4 h-4 text-emerald-500" />
                      <span>
                        {formData.date
                          ? new Date(formData.date).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })
                          : 'Date non définie'}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-emerald-500" />
                      <span className="truncate">{formData.location || 'Lieu non défini'}</span>
                    </div>
                  </div>

                  <div className="border-t border-gray-100 pt-4 mt-4">
                    <div className="w-full h-2 bg-gray-100 rounded-full mb-4 overflow-hidden">
                      <div className="w-0 h-full bg-emerald-500"></div>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-xs font-semibold text-emerald-600 bg-emerald-50 px-2 py-1 rounded">
                        0 Validés
                      </span>
                      <span className="text-xs text-gray-400">0 / 0 Tickets</span>
                    </div>
                  </div>
                </div>
              </div>
              {/* End Card Preview */}
            </div>

            <div className="mt-8 p-4 rounded-xl bg-white/10 backdrop-blur-md border border-white/10">
              <div className="flex gap-3">
                <div className="w-1 h-full bg-emerald-500 rounded-full"></div>
                <div>
                  <p className="text-xs text-emerald-300 font-bold uppercase mb-1">Conseil IA</p>
                  <p className="text-xs text-white/80 leading-relaxed">
                    Les événements avec des images de haute qualité et des descriptions précises vendent 25% de billets en plus.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
