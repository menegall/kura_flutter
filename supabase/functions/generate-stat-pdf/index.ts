import { serve } from "std/server";
import { createClient } from "@supabase/supabase-js";
import { PDFDocument, rgb, StandardFonts, PDFFont } from "pdf-lib";

// Helper function to format duration
function formatDuration(hours: number): string {
  const h = Math.floor(hours);
  const m = Math.round((hours - h) * 60);
  if (h === 0) {
    return `${m} minuti`;
  } else if (m === 0) {
    return `${h}h`;
  } else {
    return `${h}h e ${m} minuti`;
  }
}

// Helper function to wrap text based on a maximum width
function splitTextIntoLines(
  text: string,
  font: PDFFont,
  fontSize: number,
  maxWidth: number,
): string[] {
  if (!text) return [""];
  const words = text.split(" ");
  const lines: string[] = [];
  let currentLine = words[0];

  for (let i = 1; i < words.length; i++) {
    const word = words[i];
    const width = font.widthOfTextAtSize(currentLine + " " + word, fontSize);
    if (width < maxWidth) {
      currentLine += " " + word;
    } else {
      lines.push(currentLine);
      currentLine = word;
    }
  }
  lines.push(currentLine);
  return lines;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Nessun header di autorizzazione fornito" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Initialize Supabase client using user JWT to respect RLS
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Fetch user to get their name
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Token non valido o utente non trovato" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const curatoreName = user.user_metadata?.name ?? "Curatore";

    // Parse request payload
    const { pupil_id, period_type, year, month, day } = await req.json();
    if (!pupil_id || !period_type || !year) {
      return new Response(
        JSON.stringify({
          error:
            "Parametri mancanti: pupil_id, period_type, year sono obbligatori",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 1. Fetch pupil details
    const { data: pupil, error: pupilError } = await supabase
      .from("pupils")
      .select("*")
      .eq("id", pupil_id)
      .single();

    if (pupilError || !pupil) {
      return new Response(
        JSON.stringify({ error: "Pupillo non trovato o accesso negato" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 2. Build date filters and query activities
    let query = supabase
      .from("activities")
      .select("*")
      .eq("pupil_id", pupil_id);

    let periodLabel = "";

    if (period_type === "Giorno") {
      const formattedDay = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
      query = query.eq("activity_date", formattedDay);
      periodLabel = `${String(day).padStart(2, "0")}/${String(month).padStart(2, "0")}/${year}`;
    } else if (period_type === "Mese") {
      const lastDay = new Date(year, month, 0).getDate();
      const startOfMonth = `${year}-${String(month).padStart(2, "0")}-01`;
      const endOfMonth = `${year}-${String(month).padStart(2, "0")}-${lastDay}`;
      query = query
        .gte("activity_date", startOfMonth)
        .lte("activity_date", endOfMonth);

      const monthsItalian = [
        "Gennaio",
        "Febbraio",
        "Marzo",
        "Aprile",
        "Maggio",
        "Giugno",
        "Luglio",
        "Agosto",
        "Settembre",
        "Ottobre",
        "Novembre",
        "Dicembre",
      ];
      periodLabel = `${monthsItalian[month - 1]} ${year}`;
    } else if (period_type === "Anno") {
      query = query
        .gte("activity_date", `${year}-01-01`)
        .lte("activity_date", `${year}-12-31`);
      periodLabel = `Anno ${year}`;
    }

    const { data: activities, error: activitiesError } = await query.order(
      "activity_date",
      { ascending: true },
    );

    if (activitiesError) {
      return new Response(
        JSON.stringify({ error: "Errore nel recupero delle attività" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 3. Financial calculations
    let workedHours = 0.0;
    let totalKm = 0.0;
    let totalStamps = 0.0;
    let totalOtherExpenses = 0.0;

    for (const act of activities || []) {
      const duration = Number(act.duration) || 0.0;
      const kilometers = Number(act.kilometers) || 0.0;
      const stamp = Number(act.stamp) || 0.0;
      const other_expenses = Number(act.other_expenses) || 0.0;

      workedHours += duration;
      if (act.kilometers != null) totalKm += kilometers;
      if (act.stamp != null) totalStamps += stamp;
      if (act.other_expenses != null) totalOtherExpenses += other_expenses;
    }

    const hourlyRate = Number(pupil.tarif) || 0.0;
    const kmRate = Number(pupil.km_tarif) || 0.0;
    const hoursCost = workedHours * hourlyRate;
    const kmCost = totalKm * kmRate;
    const grandTotal = hoursCost + kmCost + totalStamps + totalOtherExpenses;

    // 4. Generate PDF
    const pdfDoc = await PDFDocument.create();
    let page = pdfDoc.addPage([595.28, 841.89]); // A4
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
    let y = 800;

    // Header
    page.drawText("REPORT PRESTAZIONI E ATTIVITÀ", {
      x: 40,
      y,
      size: 20,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    y -= 25;
    page.drawLine({
      start: { x: 40, y },
      end: { x: 555, y },
      thickness: 1.5,
      color: rgb(0.9, 0.87, 0.83),
    });
    y -= 30;

    // Metadata
    page.drawText(`Curatore: ${curatoreName}`, { x: 40, y, size: 11, font });
    page.drawText(`Periodo di riferimento: ${periodLabel}`, {
      x: 300,
      y,
      size: 11,
      font,
    });
    y -= 18;
    page.drawText(`Pupillo: ${pupil.name}`, {
      x: 40,
      y,
      size: 11,
      font: boldFont,
    });
    page.drawText(`Generato il: ${new Date().toLocaleDateString("it-CH")}`, {
      x: 300,
      y,
      size: 11,
      font,
    });
    y -= 35;

    // Applied Rates Table
    page.drawText("TARIFFE APPLICATE", {
      x: 40,
      y,
      size: 11,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    y -= 18;
    page.drawText(`Tariffa Oraria: ${hourlyRate.toFixed(2)} CHF/h`, {
      x: 50,
      y,
      size: 10,
      font,
    });
    page.drawText(`Tariffa Kilometrica: ${kmRate.toFixed(2)} CHF/km`, {
      x: 300,
      y,
      size: 10,
      font,
    });
    y -= 30;

    const hasOtherExpenses = totalOtherExpenses > 0;
    const boxHeight = hasOtherExpenses ? 155 : 135;
    const boxOffset = hasOtherExpenses ? 145 : 125;

    // Financial Summary Panel
    page.drawRectangle({
      x: 40,
      y: y - boxOffset,
      width: 515,
      height: boxHeight,
      color: rgb(0.98, 0.98, 0.97),
      borderColor: rgb(0.9, 0.87, 0.83),
      borderWidth: 1,
    });

    let boxY = y - 20;
    page.drawText("RIEPILOGO COMPLESSIVO", {
      x: 55,
      y: boxY,
      size: 11,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    boxY -= 20;

    // Hours
    page.drawText(`Ore totali svolte:`, { x: 55, y: boxY, size: 10, font });
    page.drawText(formatDuration(workedHours), {
      x: 180,
      y: boxY,
      size: 10,
      font: boldFont,
    });
    page.drawText(
      `${formatDuration(workedHours)} x ${hourlyRate.toFixed(2)} CHF =`,
      { x: 275, y: boxY, size: 10, font },
    );
    page.drawText(`${hoursCost.toFixed(2)} CHF`, {
      x: 440,
      y: boxY,
      size: 10,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    boxY -= 18;

    // Kilometers
    page.drawText(`Distanza percorsa:`, { x: 55, y: boxY, size: 10, font });
    page.drawText(`${totalKm.toFixed(1)} km`, {
      x: 180,
      y: boxY,
      size: 10,
      font: boldFont,
    });
    page.drawText(`${totalKm.toFixed(1)} km x ${kmRate.toFixed(2)} CHF =`, {
      x: 260,
      y: boxY,
      size: 10,
      font,
    });
    page.drawText(`${kmCost.toFixed(2)} CHF`, {
      x: 440,
      y: boxY,
      size: 10,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    boxY -= 18;

    // Stamps
    page.drawText(`Spese francobolli (mail):`, {
      x: 55,
      y: boxY,
      size: 10,
      font,
    });
    page.drawText(`${totalStamps.toFixed(2)} CHF`, {
      x: 440,
      y: boxY,
      size: 10,
      font: boldFont,
      color: rgb(0.76, 0.43, 0.31),
    });
    boxY -= 18;

    // Other expenses
    if (hasOtherExpenses) {
      page.drawText(`Altre spese rimborsabili:`, {
        x: 55,
        y: boxY,
        size: 10,
        font,
      });
      page.drawText(`${totalOtherExpenses.toFixed(2)} CHF`, {
        x: 440,
        y: boxY,
        size: 10,
        font: boldFont,
        color: rgb(0.76, 0.43, 0.31),
      });
      boxY -= 18;
    }
    boxY -= 4;

    // Separator line
    page.drawLine({
      start: { x: 55, y: boxY },
      end: { x: 540, y: boxY },
      thickness: 0.8,
      color: rgb(0.9, 0.87, 0.83),
    });
    boxY -= 18;

    // Grand Total
    page.drawText("TOTALE DA FATTURARE:", {
      x: 55,
      y: boxY,
      size: 11,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    page.drawText(`${grandTotal.toFixed(2)} CHF`, {
      x: 440,
      y: boxY,
      size: 12,
      font: boldFont,
      color: rgb(0.76, 0.43, 0.31),
    });

    y -= boxOffset + 45;

    // Activities List Title
    page.drawText("DETTAGLIO PRESTAZIONI EFFETTUATE", {
      x: 40,
      y,
      size: 11,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    y -= 20;

    // Table header layout with new structured columns
    page.drawRectangle({
      x: 40,
      y: y - 5,
      width: 515,
      height: 18,
      color: rgb(0.9, 0.87, 0.83),
    });
    page.drawText("Data", {
      x: 45,
      y,
      size: 9,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    page.drawText("Tipo Attività", {
      x: 95,
      y,
      size: 9,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    page.drawText("Tempo", {
      x: 165,
      y,
      size: 9,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    page.drawText("Km", {
      x: 225,
      y,
      size: 9,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    page.drawText("Spese", {
      x: 265,
      y,
      size: 9,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });
    page.drawText("Descrizione / Note", {
      x: 365,
      y,
      size: 9,
      font: boldFont,
      color: rgb(0.29, 0.35, 0.25),
    });

    y -= 20;

    const typeLabels: Record<string, string> = {
      call: "Telefonata",
      transfert: "Trasferta",
      mail: "Email/Lettera",
      meeting_various: "Incontro Varie",
      meeting_pupils: "Incontro Pupillo",
      other: "Altro",
    };

    // Table Body loop
    for (const act of activities || []) {
      const desc = act.description || "";

      // Define column max widths based on new structural layout spacing
      const speseMaxWidth = 95; // X goes from 265 to 360
      const descMaxWidth = 190; // X goes from 365 to 555

      // Prepare multi-line array for Expenses column
      const speseLines: string[] = [];
      if (act.stamp != null && Number(act.stamp) > 0) {
        speseLines.push(`francobolli: ${Number(act.stamp).toFixed(2)} CHF`);
      }
      if (act.other_expenses != null && Number(act.other_expenses) > 0) {
        speseLines.push(`altre: ${Number(act.other_expenses).toFixed(2)} CHF`);
      }
      if (speseLines.length === 0) {
        speseLines.push("-");
      }

      // Format single-line static text inputs
      const tempoStr =
        act.duration != null && Number(act.duration) > 0
          ? formatDuration(Number(act.duration))
          : "-";
      const kmStr =
        act.kilometers != null && Number(act.kilometers) > 0
          ? `${Number(act.kilometers).toFixed(1)} km`
          : "-";

      // Split Description column into lines
      const descLines = splitTextIntoLines(desc, font, 8, descMaxWidth);

      // Get the highest number of lines rendered in either Expenses or Description column
      const maxLines = Math.max(speseLines.length, descLines.length);

      const lineHeight = 11;
      const textBlockHeight = (maxLines - 1) * lineHeight;
      const rowNeededSpace = textBlockHeight + 20;

      // Page break verification before drawing
      if (y - rowNeededSpace < 50) {
        page = pdfDoc.addPage([595.28, 841.89]);
        y = 780;

        // Redraw table headers on the new page
        page.drawRectangle({
          x: 40,
          y: y - 5,
          width: 515,
          height: 18,
          color: rgb(0.9, 0.87, 0.83),
        });
        page.drawText("Data", {
          x: 45,
          y,
          size: 9,
          font: boldFont,
          color: rgb(0.29, 0.35, 0.25),
        });
        page.drawText("Tipo Attività", {
          x: 95,
          y,
          size: 9,
          font: boldFont,
          color: rgb(0.29, 0.35, 0.25),
        });
        page.drawText("Tempo", {
          x: 165,
          y,
          size: 9,
          font: boldFont,
          color: rgb(0.29, 0.35, 0.25),
        });
        page.drawText("Km", {
          x: 225,
          y,
          size: 9,
          font: boldFont,
          color: rgb(0.29, 0.35, 0.25),
        });
        page.drawText("Spese", {
          x: 265,
          y,
          size: 9,
          font: boldFont,
          color: rgb(0.29, 0.35, 0.25),
        });
        page.drawText("Descrizione / Note", {
          x: 365,
          y,
          size: 9,
          font: boldFont,
          color: rgb(0.29, 0.35, 0.25),
        });
        y -= 20;
      }

      const dateObj = new Date(act.activity_date);
      const formattedActDate = `${String(dateObj.getDate()).padStart(2, "0")}/${String(dateObj.getMonth() + 1).padStart(2, "0")}/${dateObj.getFullYear()}`;
      const typeLabel = typeLabels[act.type] || act.type;

      // Draw baseline single-line standard fields
      page.drawText(formattedActDate, { x: 45, y, size: 8, font });
      page.drawText(typeLabel, { x: 95, y, size: 8, font });
      page.drawText(tempoStr, { x: 165, y, size: 8, font });
      page.drawText(kmStr, { x: 225, y, size: 8, font });

      // Draw wrapped multi-line Expenses column
      for (let i = 0; i < speseLines.length; i++) {
        page.drawText(speseLines[i], {
          x: 265,
          y: y - i * lineHeight,
          size: 8,
          font,
        });
      }

      // Draw wrapped multi-line Description column
      for (let i = 0; i < descLines.length; i++) {
        page.drawText(descLines[i], {
          x: 365,
          y: y - i * lineHeight,
          size: 8,
          font,
        });
      }

      // Draw horizontal divider line exactly 6 points below the lowest text line block
      const dividerY = y - textBlockHeight - 6;
      page.drawLine({
        start: { x: 40, y: dividerY },
        end: { x: 555, y: dividerY },
        thickness: 0.5,
        color: rgb(0.92, 0.92, 0.92),
      });

      // Advance baseline tracker safely for the next row
      y = dividerY - 14;
    }

    const pdfBytes = await pdfDoc.save();

    return new Response(pdfBytes, {
      status: 200,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/pdf",
        "Content-Disposition": `inline; filename="statistiche_${pupil.name}.pdf"`,
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
