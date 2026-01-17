const API_BASE = '/api';

// Utilities
function showToast(message) {
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.textContent = message;
    document.body.appendChild(toast);

    // Trigger reflow
    toast.offsetHeight;

    requestAnimationFrame(() => {
        toast.classList.add('show');
    });

    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

async function copyToClipboard(text, element) {
    try {
        await navigator.clipboard.writeText(text);
        showToast('Copied to clipboard!');

        // Visual feedback
        const originalText = element.textContent;
        element.textContent = 'Copied!';
        setTimeout(() => {
            element.textContent = originalText;
        }, 1500);
    } catch (err) {
        showToast('Failed to copy');
        console.error('Copy failed', err);
    }
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('default', {
        dateStyle: 'medium',
        timeStyle: 'short'
    }).format(date);
}

function updateCountdown(expiresAtStr, elementId) {
    const element = document.getElementById(elementId);
    if (!element) return;

    const expiresAt = new Date(expiresAtStr).getTime();

    function update() {
        const now = new Date().getTime();
        const distance = expiresAt - now;

        if (distance < 0) {
            const lang = window.localStorage.getItem('appLang') || 'en';
            const expiredText = window.translations ? (window.translations[lang]['public.link_expired'] || "Expired") : "Expired";
            element.innerHTML = expiredText;
            showToast("Session expired");
            setTimeout(() => window.location.href = '/', 2000);
            return;
        }

        const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((distance % (1000 * 60)) / 1000);

        const lang = window.localStorage.getItem('appLang') || 'en';
        const label = window.translations ? (window.translations[lang]['private.expires_in'] || "Expires in:") : "Expires in:";

        element.innerHTML = `${label} <strong>${hours}h ${minutes}m ${seconds}s</strong>`;
    }

    update();
    setInterval(update, 1000);
}
