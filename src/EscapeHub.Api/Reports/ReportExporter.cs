using System.Globalization;
using System.Text;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using EscapeHub.Application.DTOs.Reports;

namespace EscapeHub.Api.Reports;

public static class ReportExporter
{
    private static readonly char[] FormulaPrefixes = ['=', '+', '-', '@', '\t', '\r'];

    public static ExportedFile Export(string report, ReportTable table, string format)
    {
        var fileName = $"{report}-{table.From:yyyyMMdd}-{table.To:yyyyMMdd}";
        return format == ReportOptions.Csv
            ? new ExportedFile(ToCsv(table), "text/csv", fileName + ".csv")
            : new ExportedFile(ToPdf(table), "application/pdf", fileName + ".pdf");
    }

    private static byte[] ToCsv(ReportTable table)
    {
        var csv = new StringBuilder();
        csv.AppendLine(string.Join(',', table.Columns.Select(Escape)));
        foreach (var row in table.Rows)
            csv.AppendLine(string.Join(',', row.Select(Escape)));
        return Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv.ToString())).ToArray();
    }

    private static string Escape(string value)
    {
        var safe = value.Length > 0 && FormulaPrefixes.Contains(value[0]) ? "'" + value : value;
        return safe.IndexOfAny([',', '"', '\n', '\r']) < 0 ? safe : $"\"{safe.Replace("\"", "\"\"")}\"";
    }

    private static byte[] ToPdf(ReportTable table) =>
        Document.Create(document => document.Page(page =>
        {
            page.Size(table.Columns.Count > 5 ? PageSizes.A4.Landscape() : PageSizes.A4);
            page.Margin(30);
            page.DefaultTextStyle(style => style.FontSize(10));
            page.Header().Column(header =>
            {
                header.Item().Text($"EscapeHub - {table.Title}").FontSize(18).SemiBold();
                header.Item().Text($"Period: {Date(table.From)} - {Date(table.To)}").FontColor(Colors.Grey.Darken1);
            });
            page.Content().PaddingTop(15).Element(content => Body(content, table));
            page.Footer().AlignRight().Text(text =>
            {
                text.Span($"Generated {DateTime.UtcNow:yyyy-MM-dd HH:mm} UTC, page ");
                text.CurrentPageNumber();
                text.Span(" of ");
                text.TotalPages();
            });
        })).GeneratePdf();

    private static void Body(IContainer container, ReportTable table)
    {
        if (table.Rows.Count == 0)
        {
            container.Text("There is no data for the selected period.");
            return;
        }

        container.Table(grid =>
        {
            grid.ColumnsDefinition(columns => table.Columns.ForEach(_ => columns.RelativeColumn()));
            grid.Header(header => table.Columns.ForEach(column =>
                header.Cell().Background(Colors.Grey.Lighten3).Padding(4).Text(column).SemiBold()));
            foreach (var cell in table.Rows.SelectMany(row => row))
                grid.Cell().BorderBottom(0.5f).BorderColor(Colors.Grey.Lighten2).Padding(4).Text(cell);
        });
    }

    private static string Date(DateTime value) => value.ToString("dd.MM.yyyy", CultureInfo.InvariantCulture);
}
