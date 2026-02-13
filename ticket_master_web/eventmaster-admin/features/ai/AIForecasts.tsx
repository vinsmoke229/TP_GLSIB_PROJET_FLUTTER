import React, { useState, useEffect } from 'react';
import { TrendingUp, TrendingDown, BarChart3, RefreshCw, AlertCircle } from 'lucide-react';
import { Event, SalesData, AIPrediction } from '../../types';
import { generateSalesAnalysis } from '../../services/geminiService';

interface AIForecastsProps {
  events: Event[];
  salesData: SalesData[];
}

const AIForecasts: React.FC<AIForecastsProps> = ({ events, salesData }) => {
  const [prediction, setPrediction] = useState<AIPrediction | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadPrediction = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await generateSalesAnalysis(events, salesData);
      setPrediction(result);
    } catch (err) {
      setError('Impossible de générer les prévisions pour le moment.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadPrediction();
  }, [events, salesData]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const getConfidenceColor = (score: number) => {
    if (score >= 80) return 'text-green-600';
    if (score >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getConfidenceBg = (score: number) => {
    if (score >= 80) return 'bg-green-100 dark:bg-green-900/30';
    if (score >= 60) return 'bg-yellow-100 dark:bg-yellow-900/30';
    return 'bg-red-100 dark:bg-red-900/30';
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Prévisions IA</h2>
          <p className="text-gray-600 dark:text-gray-400 mt-1">
            Analyses et prédictions basées sur vos données d'événements
          </p>
        </div>
        <button
          onClick={loadPrediction}
          disabled={isLoading}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:bg-gray-400 text-white rounded-lg transition-colors"
        >
          <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
          Actualiser
        </button>
      </div>

      {error && (
        <div className="bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-800 rounded-lg p-4">
          <div className="flex items-center gap-2">
            <AlertCircle className="w-5 h-5 text-red-600" />
            <p className="text-red-800 dark:text-red-200">{error}</p>
          </div>
        </div>
      )}

      {isLoading && !prediction && (
        <div className="flex items-center justify-center py-12">
          <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
            <RefreshCw className="w-5 h-5 animate-spin" />
            <span>Génération des prévisions...</span>
          </div>
        </div>
      )}

      {prediction && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Summary Card */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                <BarChart3 className="w-5 h-5 text-blue-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                Résumé de Performance
              </h3>
            </div>
            <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
              {prediction.summary}
            </p>
          </div>

          {/* Suggested Action Card */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
                <TrendingUp className="w-5 h-5 text-emerald-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                Action Suggérée
              </h3>
            </div>
            <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
              {prediction.suggestedAction}
            </p>
          </div>

          {/* Projected Revenue Card */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                <TrendingUp className="w-5 h-5 text-purple-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                Revenu Projeté (Mois Prochain)
              </h3>
            </div>
            <div className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
              {formatCurrency(prediction.projectedRevenue)}
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Basé sur les tendances actuelles
            </p>
          </div>

          {/* Confidence Score Card */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className={`w-10 h-10 rounded-lg ${getConfidenceBg(prediction.confidenceScore)} flex items-center justify-center`}>
                {prediction.confidenceScore >= 70 ? (
                  <TrendingUp className={`w-5 h-5 ${getConfidenceColor(prediction.confidenceScore)}`} />
                ) : (
                  <TrendingDown className={`w-5 h-5 ${getConfidenceColor(prediction.confidenceScore)}`} />
                )}
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                Score de Confiance
              </h3>
            </div>
            <div className={`text-3xl font-bold mb-2 ${getConfidenceColor(prediction.confidenceScore)}`}>
              {prediction.confidenceScore}%
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className={`h-2 rounded-full transition-all duration-300 ${
                  prediction.confidenceScore >= 80 ? 'bg-green-500' :
                  prediction.confidenceScore >= 60 ? 'bg-yellow-500' : 'bg-red-500'
                }`}
                style={{ width: `${prediction.confidenceScore}%` }}
              ></div>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">
              Fiabilité de la prédiction
            </p>
          </div>
        </div>
      )}

      {/* Additional Insights */}
      {prediction && (
        <div className="bg-gradient-to-r from-emerald-50 to-blue-50 dark:from-emerald-900/20 dark:to-blue-900/20 rounded-xl border border-emerald-200 dark:border-emerald-800 p-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-3">
            Insights Supplémentaires
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-emerald-600">
                {events.filter(e => e.status === 'published').length}
              </div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Événements Actifs</p>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {events.reduce((acc, e) => acc + e.ticketTypes.reduce((sum, t) => sum + t.quantitySold, 0), 0)}
              </div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Billets Vendus</p>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">
                {formatCurrency(salesData.reduce((acc, s) => acc + s.revenue, 0))}
              </div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Revenus Totaux</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AIForecasts;
