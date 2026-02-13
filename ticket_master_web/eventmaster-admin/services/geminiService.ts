import { GoogleGenAI, Type } from "@google/genai";
import { Event, SalesData, AIPrediction, AIMessage } from "../types";

let ai: GoogleGenAI | null = null;

const getAI = () => {
  if (!ai && process.env.API_KEY) {
    ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
  }
  return ai;
};

export const generateSalesAnalysis = async (
  events: Event[],
  recentSales: SalesData[]
): Promise<AIPrediction> => {
  
  const prompt = `
    Agis comme un expert en data analysis pour l'événementiel.
    Voici les données actuelles de nos événements et ventes récentes :
    
    Événements: ${JSON.stringify(events.map(e => ({ title: e.title, sold: e.ticketTypes.reduce((acc, t) => acc + t.quantitySold, 0), validated: e.ticketsValidated })))}
    Ventes récentes (30 jours): ${JSON.stringify(recentSales)}

    Analyse ces données et fournis :
    1. Un résumé concis de la performance actuelle.
    2. Une action suggérée pour améliorer les ventes (ex: promo, marketing).
    3. Une projection de revenu estimée pour le mois prochain.
    4. Un score de confiance sur cette prédiction (0-100).
    
    Réponds uniquement avec du JSON valide selon le schéma fourni.
  `;

  try {
    const aiInstance = getAI();
    if (!aiInstance) {
      throw new Error("API Key not configured");
    }
    
    const response = await aiInstance.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            summary: { type: Type.STRING },
            suggestedAction: { type: Type.STRING },
            projectedRevenue: { type: Type.NUMBER },
            confidenceScore: { type: Type.NUMBER }
          },
          required: ["summary", "suggestedAction", "projectedRevenue", "confidenceScore"]
        }
      }
    });

    if (response.text) {
        return JSON.parse(response.text) as AIPrediction;
    }
    throw new Error("Empty response from AI");

  } catch (error) {
    console.error("Error generating AI analysis:", error);
    return {
      summary: "Impossible de générer l'analyse pour le moment.",
      suggestedAction: "Vérifiez votre clé API.",
      projectedRevenue: 0,
      confidenceScore: 0
    };
  }
};

export const chatWithAI = async (messages: AIMessage[], context: { events: Event[]; salesData: SalesData[] }): Promise<string> => {
  const conversationHistory = messages.map(m => `${m.role}: ${m.content}`).join('\n');

  const prompt = `
    Tu es un assistant IA pour EventMaster, une plateforme de gestion d'événements. Aide les utilisateurs avec la planification d'événements, l'analyse et la gestion.

    Contexte :
    Événements : ${JSON.stringify(context.events.map(e => ({ title: e.title, date: e.date, location: e.location, status: e.status, ticketsSold: e.ticketTypes.reduce((acc, t) => acc + t.quantitySold, 0) })))}
    Ventes récentes : ${JSON.stringify(context.salesData)}

    Historique de conversation :
    ${conversationHistory}

    Réponds de manière utile et concise en français.
  `;

  try {
    const aiInstance = getAI();
    if (!aiInstance) {
      throw new Error("API Key not configured");
    }
    
    const response = await aiInstance.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: prompt
    });

    return response.text || "Désolé, je n'ai pas pu générer une réponse.";
  } catch (error) {
    console.error("Error chatting with AI:", error);
    return "Une erreur s'est produite. Veuillez réessayer.";
  }
};
