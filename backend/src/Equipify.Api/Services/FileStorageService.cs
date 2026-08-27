using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.Processing;

namespace Equipify.Api.Services;

public interface IFileStorageService
{
    /// <summary>Validates, compresses, and saves uploaded images; returns web-relative paths.</summary>
    Task<List<string>> SaveImagesAsync(IEnumerable<IFormFile>? files, string subFolder);
}

/// <summary>
/// Saves uploaded images under wwwroot/uploads. Validates extension + magic bytes,
/// compresses/resizes to a maximum of 1920px on the longest side at JPEG quality 80,
/// and names files with GUIDs so nothing user-controlled touches the filesystem.
/// </summary>
public class FileStorageService : IFileStorageService
{
    private const long MaxRawBytes = 10 * 1024 * 1024;   // 10 MB raw upload limit
    private const int MaxDimension = 1920;                // max px on longest side
    private const int JpegQuality = 80;                   // output JPEG quality

    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".gif", ".webp"
    };

    private readonly IWebHostEnvironment _env;
    private readonly ILogger<FileStorageService> _logger;

    public FileStorageService(IWebHostEnvironment env, ILogger<FileStorageService> logger)
    {
        _env = env;
        _logger = logger;
    }

    public async Task<List<string>> SaveImagesAsync(IEnumerable<IFormFile>? files, string subFolder)
    {
        var paths = new List<string>();
        if (files is null) return paths;

        foreach (var file in files.Take(6))
        {
            var path = await CompressAndSaveAsync(file, subFolder);
            if (path is not null) paths.Add(path);
        }

        return paths;
    }

    private async Task<string?> CompressAndSaveAsync(IFormFile file, string subFolder)
    {
        if (file is null || file.Length == 0) return null;

        if (file.Length > MaxRawBytes)
        {
            _logger.LogWarning("Rejected upload {Name}: exceeds {Max} MB", file.FileName, MaxRawBytes / 1024 / 1024);
            return null;
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(ext))
        {
            _logger.LogWarning("Rejected upload {Name}: extension {Ext} not allowed", file.FileName, ext);
            return null;
        }

        if (!await HasValidSignatureAsync(file, ext))
        {
            _logger.LogWarning("Rejected upload {Name}: content is not a valid image", file.FileName);
            return null;
        }

        var root = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
        var folder = Path.Combine(root, "uploads", subFolder);
        Directory.CreateDirectory(folder);

        var fileName = $"{Guid.NewGuid():N}.jpg";
        var fullPath = Path.Combine(folder, fileName);

        try
        {
            await using var inputStream = file.OpenReadStream();
            using var image = await Image.LoadAsync(inputStream);

            // Resize if either dimension exceeds MaxDimension
            if (image.Width > MaxDimension || image.Height > MaxDimension)
            {
                image.Mutate(x => x.Resize(new ResizeOptions
                {
                    Size = new Size(MaxDimension, MaxDimension),
                    Mode = ResizeMode.Max
                }));
            }

            // Always save as JPEG for consistent, compressed output
            await image.SaveAsJpegAsync(fullPath, new JpegEncoder
            {
                Quality = JpegQuality
            });

            _logger.LogInformation("Saved {Name} → {File} ({SizeKB} KB)", file.FileName, fileName,
                new FileInfo(fullPath).Length / 1024);

            return $"/uploads/{subFolder}/{fileName}";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to process image {Name}", file.FileName);
            return null;
        }
    }

    private static async Task<bool> HasValidSignatureAsync(IFormFile file, string ext)
    {
        await using var stream = file.OpenReadStream();
        var header = new byte[12];
        var read = await stream.ReadAsync(header.AsMemory(0, header.Length));
        stream.Position = 0;
        if (read < 4) return false;

        return ext switch
        {
            ".jpg" or ".jpeg" => header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF,
            ".png" => header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47,
            ".gif" => header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46,
            ".webp" => header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46
                       && header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50,
            _ => false
        };
    }
}
