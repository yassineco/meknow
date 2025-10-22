export function cn(...classes: (string | undefined | null | false)[]) {
  return classes.filter(Boolean).join(' ');
}

export function getImageUrl(url?: string): string {
  if (!url) return '/placeholder.jpg';
  if (url.startsWith('http')) return url;
  
  // Pour les URLs relatives (qui commencent par /), ajouter le backend API URL
  if (url.startsWith('/')) {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9000';
    return `${apiUrl}${url}`;
  }
  
  return url;
}

export function truncate(str: string, length: number): string {
  if (str.length <= length) return str;
  return str.slice(0, length) + '...';
}
