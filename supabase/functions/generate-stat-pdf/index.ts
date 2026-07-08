import { serve } from "std/server"
import { createClient } from "@supabase/supabase-js"
import { PDFDocument, rgb, StandardFonts } from "pdf-lib"


function formatDuration(hours: number): string {
  const h = Math.floor(hours)
  const m = Math.round((hours - h) * 60)
  if (h === 0) {
    return `${m} minuti`
  } else if (m === 0) {
    return `${h}h`
  } else {
    return `${h}h e ${m} minuti`
  }
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
serve(async (req) => {
  // Gestione preflight OPTIONS per CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Nessun header di autorizzazione fornito' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    // Inizializza il client Supabase con il JWT dell'utente per rispettare RLS
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ""
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ""
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })
    // Recupera l'utente per avere il suo nome
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Token non valido o utente non trovato' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    const curatoreName = user.user_metadata?.name ?? 'Curatore'
    // Leggi i parametri della richiesta
    const { pupil_id, period_type, year, month, day } = await req.json()
    if (!pupil_id || !period_type || !year) {
      return new Response(JSON.stringify({ error: 'Parametri mancanti: pupil_id, period_type, year sono obbligatori' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    // 1. Recupera i dettagli del pupillo
    const { data: pupil, error: pupilError } = await supabase
      .from('pupils')
      .select('*')
      .eq('id', pupil_id)
      .single()
    if (pupilError || !pupil) {
      return new Response(JSON.stringify({ error: 'Pupillo non trovato o accesso negato' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    // 2. Costruisci il filtro per la data ed esegui la query delle attività
    let query = supabase.from('activities').select('*').eq('pupil_id', pupil_id)
    let periodLabel = ''
    if (period_type === 'Giorno') {
      const formattedDay = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
      query = query.eq('activity_date', formattedDay)
      periodLabel = `${String(day).padStart(2, '0')}/${String(month).padStart(2, '0')}/${year}`
    } else if (period_type === 'Mese') {
      const lastDay = new Date(year, month, 0).getDate()
      const startOfMonth = `${year}-${String(month).padStart(2, '0')}-01`
      const endOfMonth = `${year}-${String(month).padStart(2, '0')}-${lastDay}`
      query = query.gte('activity_date', startOfMonth).lte('activity_date', endOfMonth)
      const monthsItalian = [
        'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
        'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
      ]
      periodLabel = `${monthsItalian[month - 1]} ${year}`
    } else if (period_type === 'Anno') {
      query = query.gte('activity_date', `${year}-01-01`).lte('activity_date', `${year}-12-31`)
      periodLabel = `Anno ${year}`
    }
    const { data: activities, error: activitiesError } = await query.order('activity_date', { ascending: true })
    if (activitiesError) {
      return new Response(JSON.stringify({ error: 'Errore nel recupero delle attività' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    // 3. Esegui i conteggi e i calcoli finanziari
    let workedHours = 0.0
    let totalKm = 0.0
    let totalStamps = 0.0
    const categoryHours: Record<string, number> = {
      call: 0.0,
      meeting_various: 0.0,
      meeting_pupils: 0.0,
      other: 0.0,
      mail: 0.0,
    }
    for (const act of activities || []) {
      const duration = Number(act.duration) || 0.0
      const kilometers = Number(act.kilometers) || 0.0
      const stamp = Number(act.stamp) || 0.0
      workedHours += duration
      if (act.kilometers != null) totalKm += kilometers
      if (act.stamp != null) totalStamps += stamp
      if (act.type in categoryHours) {
        categoryHours[act.type] += duration
      }
    }
    const hourlyRate = Number(pupil.tarif) || 0.0
    const kmRate = Number(pupil.km_tarif) || 0.0
    const hoursCost = workedHours * hourlyRate
    const kmCost = totalKm * kmRate
    const grandTotal = hoursCost + kmCost + totalStamps
    // 4. Generazione del file PDF
    const pdfDoc = await PDFDocument.create()
    let page = pdfDoc.addPage([595.28, 841.89]) // A4
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica)
    const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold)
    let y = 800
    // Intestazione
    page.drawText("REPORT PRESTAZIONI E ATTIVITÀ", { x: 40, y, size: 20, font: boldFont, color: rgb(0.29, 0.35, 0.25) }) // Dark Green
    y -= 25
    page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 1.5, color: rgb(0.9, 0.87, 0.83) }) // Beige
    y -= 30
    // Metadati Curatore e Pupillo
    page.drawText(`Curatore: ${curatoreName}`, { x: 40, y, size: 11, font })
    page.drawText(`Periodo di riferimento: ${periodLabel}`, { x: 300, y, size: 11, font })
    y -= 18
    page.drawText(`Pupillo: ${pupil.name}`, { x: 40, y, size: 11, font: boldFont })
    page.drawText(`Generato il: ${new Date().toLocaleDateString('it-CH')}`, { x: 300, y, size: 11, font })
    y -= 35
    // Tabella Tariffe Applicate
    page.drawText("TARIFFE APPLICATE", { x: 40, y, size: 11, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    y -= 18
    page.drawText(`Tariffa Oraria: ${hourlyRate.toFixed(2)} CHF/h`, { x: 50, y, size: 10, font })
    page.drawText(`Tariffa Kilometrica: ${kmRate.toFixed(2)} CHF/km`, { x: 300, y, size: 10, font })
    y -= 30
    // Pannello Riepilogo Finanziario (Box colorato)
    page.drawRectangle({
      x: 40,
      y: y - 125,
      width: 515,
      height: 135,
      color: rgb(0.98, 0.98, 0.97), // Off-white
      borderColor: rgb(0.9, 0.87, 0.83), // Beige
      borderWidth: 1,
    })
    let boxY = y - 20
    page.drawText("RIEPILOGO COMPLESSIVO", { x: 55, y: boxY, size: 11, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    boxY -= 20
    // Ore
    page.drawText(`Ore totali svolte:`, { x: 55, y: boxY, size: 10, font })
    page.drawText(formatDuration(workedHours), { x: 180, y: boxY, size: 10, font: boldFont })
    page.drawText(`${formatDuration(workedHours)} x ${hourlyRate.toFixed(2)} CHF =`, { x: 275, y: boxY, size: 10, font })
    page.drawText(`${hoursCost.toFixed(2)} CHF`, { x: 440, y: boxY, size: 10, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    boxY -= 18
    // Km
    page.drawText(`Distanza percorsa:`, { x: 55, y: boxY, size: 10, font })
    page.drawText(`${totalKm.toFixed(1)} km`, { x: 180, y: boxY, size: 10, font: boldFont })
    page.drawText(`${totalKm.toFixed(1)} km x ${kmRate.toFixed(2)} CHF =`, { x: 260, y: boxY, size: 10, font })
    page.drawText(`${kmCost.toFixed(2)} CHF`, { x: 440, y: boxY, size: 10, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    boxY -= 18
    // Spese francobolli
    page.drawText(`Spese francobolli (mail):`, { x: 55, y: boxY, size: 10, font })
    page.drawText(`${totalStamps.toFixed(2)} CHF`, { x: 440, y: boxY, size: 10, font: boldFont, color: rgb(0.76, 0.43, 0.31) }) // Terra Cotta
    boxY -= 22
    // Linea divisoria box
    page.drawLine({ start: { x: 55, y: boxY }, end: { x: 540, y: boxY }, thickness: 0.8, color: rgb(0.9, 0.87, 0.83) })
    boxY -= 18
    // Totale Complessivo
    page.drawText("TOTALE DA FATTURARE:", { x: 55, y: boxY, size: 11, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    page.drawText(`${grandTotal.toFixed(2)} CHF`, { x: 440, y: boxY, size: 12, font: boldFont, color: rgb(0.76, 0.43, 0.31) }) // Terra Cotta
    y -= 150
    // Tabella Riepilogo Categorie
    page.drawText("RESOCONTO ORE PER CATEGORIA", { x: 40, y, size: 11, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    y -= 18
    const catLabels = {
      call: "Telefonate",
      meeting_pupils: "Incontri con Pupillo",
      meeting_various: "Incontri Varie",
      mail: "Email / Lettere",
      other: "Altro"
    }
    

    for (const [key, label] of Object.entries(catLabels)) {
      const hrs = categoryHours[key] || 0.0
      page.drawText(`• ${label}: ${formatDuration(hrs)}`, { x: 50, y, size: 9, font })
      y -= 15
    }
    y -= 20
    // Elenco Dettagliato Attività
    page.drawText("DETTAGLIO PRESTAZIONI EFFETTUATE", { x: 40, y, size: 11, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    y -= 20
    // Disegna intestazione tabella prestazioni
    page.drawRectangle({ x: 40, y: y - 5, width: 515, height: 18, color: rgb(0.9, 0.87, 0.83) })
    page.drawText("Data", { x: 45, y: y, size: 9, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    page.drawText("Tipo Attività", { x: 105, y: y, size: 9, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    page.drawText("Dettagli", { x: 215, y: y, size: 9, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    page.drawText("Descrizione / Note", { x: 335, y: y, size: 9, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
    y -= 20
    const typeLabels: Record<string, string> = {
      call: 'Telefonata',
      transfert: 'Trasferta',
      mail: 'Email/Lettera',
      meeting_various: 'Incontro Varie',
      meeting_pupils: 'Incontro Pupillo',
      other: 'Altro',
    }
    for (const act of activities || []) {
      // Controlla se la pagina sta per finire e aggiungine una nuova se necessario
      if (y < 60) {
        page = pdfDoc.addPage([595.28, 841.89])
        y = 780
        // Riga intestazione tabella sulla nuova pagina
        page.drawRectangle({ x: 40, y: y - 5, width: 515, height: 18, color: rgb(0.9, 0.87, 0.83) })
        page.drawText("Data", { x: 45, y: y, size: 9, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
        page.drawText("Tipo Attività", { x: 105, y: y, size: 9, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
        page.drawText("Dettagli", { x: 215, y: y, size: 9, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
        page.drawText("Descrizione / Note", { x: 335, y: y, size: 9, font: boldFont, color: rgb(0.29, 0.35, 0.25) })
        y -= 20
      }
      const dateObj = new Date(act.activity_date)
      const formattedActDate = `${String(dateObj.getDate()).padStart(2, '0')}/${String(dateObj.getMonth() + 1).padStart(2, '0')}/${dateObj.getFullYear()}`
      const typeLabel = typeLabels[act.type] || act.type
      // Dettagli dinamici
      const detailsList = []
      if (act.duration != null) detailsList.push(formatDuration(Number(act.duration)))
      if (act.kilometers != null) detailsList.push(`${Number(act.kilometers).toFixed(1)} km`)
      if (act.stamp != null) detailsList.push(`${Number(act.stamp).toFixed(2)} CHF`)
      const detailsStr = detailsList.join(" | ")
      const desc = act.description || ""
      // Tronca la descrizione se troppo lunga per stare in tabella
      const truncatedDesc = desc.length > 35 ? desc.substring(0, 32) + "..." : desc
      page.drawText(formattedActDate, { x: 45, y, size: 8, font })
      page.drawText(typeLabel, { x: 105, y, size: 8, font })
      page.drawText(detailsStr, { x: 215, y, size: 8, font })
      page.drawText(truncatedDesc, { x: 335, y, size: 8, font })
      // Linea di divisione riga
      page.drawLine({ start: { x: 40, y: y - 6 }, end: { x: 555, y: y - 6 }, thickness: 0.5, color: rgb(0.95, 0.95, 0.95) })
      y -= 18
    }
    const pdfBytes = await pdfDoc.save()
    return new Response(pdfBytes, {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="statistiche_${pupil.name}.pdf"`,
      }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
