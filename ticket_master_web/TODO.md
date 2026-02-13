# AI Integration Task

## Objective

Integrate AI features into a unified panel similar to VSCode's AI assistant, where clicking the AI icon opens a discussion panel on the right with tabs for Chat and Forecasts.

## Current State

- AI button in header opens AIChatPanel (chat only)
- Separate sidebar tab "Prévisions IA" shows AIForecasts component
- Need to combine into one panel with internal tabs

## Tasks

- [x] Create new AIPanel.tsx component with tabs for "Discussion" and "Prévisions"
- [x] Integrate AIChatPanel content into the Discussion tab
- [x] Integrate AIForecasts content into the Prévisions tab
- [x] Update App.tsx to use AIPanel instead of separate components
- [x] Remove AI_FORECASTS tab from sidebar navigation
- [x] Update AI button to open the unified panel
- [x] Test the integration and ensure proper functionality (build successful, no compilation errors)
- [x] Ensure French language support throughout

## Notes

- Panel should slide in from the right like VSCode
- Maintain existing functionality for chat and forecasts
- Use consistent styling with the rest of the app
