// Harmonic Beacon Design System Colors
// Matching the web app palette

export const Colors = {
    // Primary - Deep calming purples/blues
    primary: {
        50: '#f0f0ff',
        100: '#e4e4ff',
        200: '#cccbff',
        300: '#a9a4ff',
        400: '#8274ff',
        500: '#6346ff',  // Main brand color
        600: '#5423f7',
        700: '#4614e3',
        800: '#3a12be',
        900: '#30119b',
        950: '#1c0869',
    },

    // Accents
    accent: {
        400: '#fbbf24',
        500: '#f59e0b',
        600: '#d97706',
    },

    // Backgrounds
    background: {
        default: '#0a0a1a',  // Deep dark
        secondary: '#12122a',
        card: 'rgba(255, 255, 255, 0.05)',
        cardHover: 'rgba(255, 255, 255, 0.08)',
    },

    // Text
    text: {
        primary: '#ffffff',
        secondary: 'rgba(255, 255, 255, 0.7)',
        muted: 'rgba(255, 255, 255, 0.4)',
    },

    // Borders
    border: {
        subtle: 'rgba(255, 255, 255, 0.08)',
        active: 'rgba(99, 70, 255, 0.5)',
    }
};

export const Gradients = {
    background: ['#0a0a1a', '#12122a'] as const,
    card: ['rgba(255,255,255,0.05)', 'rgba(255,255,255,0.01)'] as const,
    primary: ['#6346ff', '#8274ff'] as const,
};
