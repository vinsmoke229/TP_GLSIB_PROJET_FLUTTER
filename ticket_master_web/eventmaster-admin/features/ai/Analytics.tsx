import React, { useState } from 'react';
import { Sparkles, TrendingUp, AlertCircle, Loader2 } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { Event, SalesData, AIPrediction } from '../../types';
import { generateSalesAnalysis } from '../../services/geminiService';

interface AnalyticsProps {
  events: Event[];
  salesData: SalesData[];
}

export const Analytics: React.FC<AnalyticsProps> = ({ events, salesData }) => {
  const [prediction, setPrediction] = useState<AIPrediction | null>(null);
  const [loading, setLoading] = useState(false);

  const handleGeneratePrediction = async () => {
    setLoading(true);
    const result = await generateSalesAnalysis(events, salesData);
    setPrediction(result);
    setLoading(false);
  };

  const salesByEvent = events.map(e => ({
    name: e.title,
    sales: e.ticketTypes.reduce((acc, t) => acc + t.price * t.quantitySold, 0)
  }));

  return (
    <div className="space-y-6">
      <div className="bg-gradient-to-r from-emerald-500 to-teal-600 rounded-2xl p-8 text-white relative overflow-hidden">
        <div className="relative z-10">
          <h2 className="text-2xl font-bold mb-2 flex items-center gap-2">
            <Sparkles className="w-6 h-6 text-yellow-200" />
            Assistant IA & Prévisions
          </h2>
          <p className="text-emerald-50 mb-6 max-w-2xl">
            Utilisez notre modèle d'IA pour analyser vos données historiques, détecter les tendances de fraude potentielles et optimiser vos prix de billets.
          </p>
          
          {!prediction && (
            <button 
              onClick={handleGeneratePrediction}
              disabled={loading}
              className="bg-white text-emerald-600 px-6 py-2.5 rounded-lg font-semibold shadow-lg hover:bg-emerald-50 transition-all flex items-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />}
              {loading ? 'Analyse en cours...' : 'Générer un rapport IA'}
            </button>
          )}
        </div>
        
        {/* Decorative circle */}
        <div className="absolute -right-10 -bottom-10 w-64 h-64 bg-white opacity-10 rounded-full blur-3xl"></div>
      </div>

      {prediction && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 animate-fade-in">
          <div className="lg:col-span-2 bg-white p-6 rounded-xl shadow-sm border border-gray-100">
            <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-emerald-600" />
              Analyse Stratégique
            </h3>
            <p className="text-gray-600 leading-relaxed mb-4">{prediction.summary}</p>
            <div className="bg-emerald-50 p-4 rounded-lg border border-emerald-100">
              <h4 className="font-semibold text-emerald-900 text-sm mb-1">Action Recommandée</h4>
              <p className="text-emerald-700 text-sm">{prediction.suggestedAction}</p>
            </div>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
            <h3 className="font-bold text-gray-900 mb-4">Projections</h3>
            <div className="space-y-6">
              <div>
                <p className="text-sm text-gray-500 mb-1">Revenu Projeté (Mois prochain)</p>
                <p className="text-3xl font-bold text-gray-900">{prediction.projectedRevenue.toLocaleString()} FCFA</p>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-500">Indice de Confiance IA</span>
                  <span className="font-bold text-gray-900">{prediction.confidenceScore}%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className="bg-green-500 h-2 rounded-full transition-all duration-1000" 
                    style={{ width: `${prediction.confidenceScore}%` }}
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
        <h3 className="font-bold text-gray-900 mb-6">Performance par Événement</h3>
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={salesByEvent}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
              <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 12}} />
              <YAxis axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 12}} />
              <Tooltip cursor={{fill: '#f3f4f6'}} contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}/>
              <Bar dataKey="sales" radius={[4, 4, 0, 0]}>
                {salesByEvent.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={index % 2 === 0 ? '#10b981' : '#34d399'} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};
