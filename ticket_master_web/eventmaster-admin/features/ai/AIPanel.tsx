import React, { useState, useRef, useEffect } from 'react';
import { Send, X, Bot, User, Loader2, MessageSquare, TrendingUp, RefreshCw, AlertCircle } from 'lucide-react';
import { AIMessage, AIPrediction, Event, SalesData } from '../../types';
import { chatWithAI, generateSalesAnalysis } from '../../services/geminiService';

interface AIPanelProps {
  isOpen: boolean;
  onClose: () => void;
  events: Event[];
  salesData: SalesData[];
}

type AIPanelTab = 'chat' | 'forecasts';

const AIPanel: React.FC<AIPanelProps> = ({ isOpen, onClose, events, salesData }) => {
  const [activeTab, setActiveTab] = useState<AIPanelTab>('chat');

  // Chat state
  const [messages, setMessages] = useState<AIMessage[]>([
    {
      id: '1',
      role: 'assistant',
      content: 'Bonjour ! Je suis votre assistant IA pour EventMaster. Comment puis-je vous aider avec vos événements et analyses ?',
      timestamp: new Date()
    }
  ]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoadingChat, setIsLoadingChat] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Forecasts state
  const [prediction, setPrediction] = useState<AIPrediction | null>(null);
  const [isLoadingForecasts, setIsLoadingForecasts] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    if (activeTab === 'forecasts' && !prediction && !isLoadingForecasts) {
      loadPrediction();
    }
  }, [activeTab]);

  const loadPrediction = async () => {
    setIsLoadingForecasts(true);
    setError(null);
    try {
      const result = await generateSalesAnalysis(events, salesData);
      setPrediction(result);
    } catch (err) {
      setError('Impossible de générer les prévisions pour le moment.');
    } finally {
      setIsLoadingForecasts(false);
    }
  };

  const handleSendMessage = async () => {
    if (!inputMessage.trim() || isLoadingChat) return;

    const userMessage: AIMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: inputMessage.trim(),
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputMessage('');
    setIsLoadingChat(true);

    try {
      const response = await chatWithAI([...messages, userMessage], { events, salesData });

      const aiMessage: AIMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response,
        timestamp: new Date()
      };

      setMessages(prev => [...prev, aiMessage]);
    } catch (error) {
      const errorMessage: AIMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: 'Désolé, une erreur s\'est produite. Veuillez réessayer.',
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoadingChat(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

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

  if (!isOpen) return null;

  return (
    <div className="fixed right-0 top-0 h-full w-96 bg-white dark:bg-gray-800 border-l border-gray-200 dark:border-gray-700 shadow-xl z-50 flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-center gap-2">
          <Bot className="w-5 h-5 text-emerald-600" />
          <h3 className="font-semibold text-gray-900 dark:text-gray-100">Assistant IA</h3>
        </div>
        <button
          onClick={onClose}
          className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
          title="Fermer le panneau IA"
        >
          <X className="w-5 h-5 text-gray-500" />
        </button>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-gray-200 dark:border-gray-700">
        <button
          onClick={() => setActiveTab('chat')}
          className={`flex-1 py-3 px-4 text-sm font-medium transition-colors ${
            activeTab === 'chat'
              ? 'text-emerald-600 border-b-2 border-emerald-600 bg-emerald-50 dark:bg-emerald-900/20'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'
          }`}
        >
          <MessageSquare className="w-4 h-4 inline mr-2" />
          Discussion
        </button>
        <button
          onClick={() => setActiveTab('forecasts')}
          className={`flex-1 py-3 px-4 text-sm font-medium transition-colors ${
            activeTab === 'forecasts'
              ? 'text-emerald-600 border-b-2 border-emerald-600 bg-emerald-50 dark:bg-emerald-900/20'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'
          }`}
        >
          <TrendingUp className="w-4 h-4 inline mr-2" />
          Prévisions
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-hidden">
        {activeTab === 'chat' && (
          <div className="flex flex-col h-full">
            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              {messages.map((message) => (
                <div
                  key={message.id}
                  className={`flex gap-3 ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  {message.role === 'assistant' && (
                    <div className="w-8 h-8 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center flex-shrink-0">
                      <Bot className="w-4 h-4 text-emerald-600" />
                    </div>
                  )}
                  <div
                    className={`max-w-[80%] p-3 rounded-lg ${
                      message.role === 'user'
                        ? 'bg-emerald-600 text-white'
                        : 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-gray-100'
                    }`}
                  >
                    <p className="text-sm whitespace-pre-wrap">{message.content}</p>
                    <p className="text-xs opacity-70 mt-1">
                      {message.timestamp.toLocaleTimeString('fr-FR', {
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </p>
                  </div>
                  {message.role === 'user' && (
                    <div className="w-8 h-8 rounded-full bg-emerald-600 flex items-center justify-center flex-shrink-0">
                      <User className="w-4 h-4 text-white" />
                    </div>
                  )}
                </div>
              ))}
              {isLoadingChat && (
                <div className="flex gap-3 justify-start">
                  <div className="w-8 h-8 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center flex-shrink-0">
                    <Bot className="w-4 h-4 text-emerald-600" />
                  </div>
                  <div className="bg-gray-100 dark:bg-gray-700 p-3 rounded-lg">
                    <Loader2 className="w-4 h-4 animate-spin text-emerald-600" />
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <div className="p-4 border-t border-gray-200 dark:border-gray-700">
              <div className="flex gap-2">
                <input
                  type="text"
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  onKeyPress={handleKeyPress}
                  placeholder="Tapez votre message..."
                  className="flex-1 px-3 py-2 bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 outline-none"
                  disabled={isLoadingChat}
                />
                <button
                  onClick={handleSendMessage}
                  disabled={!inputMessage.trim() || isLoadingChat}
                  className="p-2 bg-emerald-600 hover:bg-emerald-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white rounded-lg transition-colors"
                  title="Envoyer le message"
                >
                  <Send className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'forecasts' && (
          <div className="h-full overflow-y-auto p-4 space-y-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100">Prévisions IA</h2>
                <p className="text-gray-600 dark:text-gray-400 mt-1 text-sm">
                  Analyses et prédictions basées sur vos données d'événements
                </p>
              </div>
              <button
                onClick={loadPrediction}
                disabled={isLoadingForecasts}
                className="flex items-center gap-2 px-3 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:bg-gray-400 text-white rounded-lg transition-colors text-sm"
              >
                <RefreshCw className={`w-4 h-4 ${isLoadingForecasts ? 'animate-spin' : ''}`} />
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

            {isLoadingForecasts && !prediction && (
              <div className="flex items-center justify-center py-8">
                <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                  <RefreshCw className="w-5 h-5 animate-spin" />
                  <span>Génération des prévisions...</span>
                </div>
              </div>
            )}

            {prediction && (
              <div className="space-y-4">
                {/* Summary Card */}
                <div className="bg-white dark:bg-gray-700 rounded-xl border border-gray-200 dark:border-gray-600 p-4">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                      <TrendingUp className="w-4 h-4 text-blue-600" />
                    </div>
                    <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                      Résumé de Performance
                    </h3>
                  </div>
                  <p className="text-gray-700 dark:text-gray-300 leading-relaxed text-sm">
                    {prediction.summary}
                  </p>
                </div>

                {/* Suggested Action Card */}
                <div className="bg-white dark:bg-gray-700 rounded-xl border border-gray-200 dark:border-gray-600 p-4">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
                      <TrendingUp className="w-4 h-4 text-emerald-600" />
                    </div>
                    <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                      Action Suggérée
                    </h3>
                  </div>
                  <p className="text-gray-700 dark:text-gray-300 leading-relaxed text-sm">
                    {prediction.suggestedAction}
                  </p>
                </div>

                {/* Projected Revenue Card */}
                <div className="bg-white dark:bg-gray-700 rounded-xl border border-gray-200 dark:border-gray-600 p-4">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-8 h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                      <TrendingUp className="w-4 h-4 text-purple-600" />
                    </div>
                    <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                      Revenu Projeté (Mois Prochain)
                    </h3>
                  </div>
                  <div className="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-2">
                    {formatCurrency(prediction.projectedRevenue)}
                  </div>
                  <p className="text-xs text-gray-600 dark:text-gray-400">
                    Basé sur les tendances actuelles
                  </p>
                </div>

                {/* Confidence Score Card */}
                <div className="bg-white dark:bg-gray-700 rounded-xl border border-gray-200 dark:border-gray-600 p-4">
                  <div className="flex items-center gap-3 mb-3">
                    <div className={`w-8 h-8 rounded-lg ${getConfidenceBg(prediction.confidenceScore)} flex items-center justify-center`}>
                      {prediction.confidenceScore >= 70 ? (
                        <TrendingUp className={`w-4 h-4 ${getConfidenceColor(prediction.confidenceScore)}`} />
                      ) : (
                        <TrendingUp className={`w-4 h-4 ${getConfidenceColor(prediction.confidenceScore)}`} />
                      )}
                    </div>
                    <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                      Score de Confiance
                    </h3>
                  </div>
                  <div className={`text-2xl font-bold mb-2 ${getConfidenceColor(prediction.confidenceScore)}`}>
                    {prediction.confidenceScore}%
                  </div>
                  <div className="w-full bg-gray-200 dark:bg-gray-600 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full transition-all duration-300 ${
                        prediction.confidenceScore >= 80 ? 'bg-green-500' :
                        prediction.confidenceScore >= 60 ? 'bg-yellow-500' : 'bg-red-500'
                      }`}
                      style={{ width: `${prediction.confidenceScore}%` }}
                    ></div>
                  </div>
                  <p className="text-xs text-gray-600 dark:text-gray-400 mt-2">
                    Fiabilité de la prédiction
                  </p>
                </div>

                {/* Additional Insights */}
                <div className="bg-gradient-to-r from-emerald-50 to-blue-50 dark:from-emerald-900/20 dark:to-blue-900/20 rounded-xl border border-emerald-200 dark:border-emerald-800 p-4">
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100 mb-3">
                    Insights Supplémentaires
                  </h3>
                  <div className="grid grid-cols-3 gap-2">
                    <div className="text-center">
                      <div className="text-lg font-bold text-emerald-600">
                        {events.filter(e => e.status === 'published').length}
                      </div>
                      <p className="text-xs text-gray-600 dark:text-gray-400">Événements Actifs</p>
                    </div>
                    <div className="text-center">
                      <div className="text-lg font-bold text-blue-600">
                        {events.reduce((acc, e) => acc + e.ticketTypes.reduce((sum, t) => sum + t.quantitySold, 0), 0)}
                      </div>
                      <p className="text-xs text-gray-600 dark:text-gray-400">Billets Vendus</p>
                    </div>
                    <div className="text-center">
                      <div className="text-lg font-bold text-purple-600">
                        {formatCurrency(salesData.reduce((acc, s) => acc + s.revenue, 0))}
                      </div>
                      <p className="text-xs text-gray-600 dark:text-gray-400">Revenus Totaux</p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default AIPanel;
