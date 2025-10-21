import { revalidatePath } from 'next/cache';
import { NextRequest, NextResponse } from 'next/server';

// 🚀 API Route pour revalidation instantanée
export async function POST(request: NextRequest) {
  try {
    // Revalide la page d'accueil immédiatement
    revalidatePath('/', 'page');
    
    // Revalide aussi les collections si elles existent
    revalidatePath('/collections/[handle]', 'page');
    
    console.log('✅ Revalidation forced after product update');
    
    return NextResponse.json({ 
      revalidated: true, 
      timestamp: new Date().toISOString() 
    });
  } catch (err) {
    console.error('❌ Error during revalidation:', err);
    return NextResponse.json({ 
      revalidated: false, 
      error: 'Failed to revalidate' 
    }, { status: 500 });
  }
}

// Endpoint GET pour vérifier le statut
export async function GET() {
  return NextResponse.json({ 
    status: 'Revalidation endpoint active',
    timestamp: new Date().toISOString()
  });
}