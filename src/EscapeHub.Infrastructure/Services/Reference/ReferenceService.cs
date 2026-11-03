using System.Linq.Expressions;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Primitives;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Reference;
using EscapeHub.Application.Exceptions;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Infrastructure.Services.Reference;

public abstract class ReferenceService<TEntity, TDto, TRequest>
    where TEntity : ReferenceEntity, new()
    where TDto : ReferenceDto
    where TRequest : ReferenceRequest
{
    private static readonly TimeSpan CacheLifetime = TimeSpan.FromMinutes(1);
    private static readonly string CachePrefix = $"reference:{typeof(TEntity).Name}";
    private static readonly string ResetKey = $"{CachePrefix}:reset";

    protected readonly AppDbContext Db;
    private readonly IMemoryCache _cache;
    private readonly ILogger _logger;

    protected ReferenceService(AppDbContext db, IMemoryCache cache, ILogger logger)
    {
        Db = db;
        _cache = cache;
        _logger = logger;
    }

    protected abstract string EntityName { get; }
    protected abstract (string One, string Many) UsageNames { get; }
    protected abstract Expression<Func<TEntity, TDto>> Projection { get; }
    protected abstract Expression<Func<TEntity, int>> Usage { get; }
    protected abstract void Apply(TEntity entity, TRequest request);

    protected virtual IQueryable<TEntity> Filter(IQueryable<TEntity> entities, SortedQuery query) => entities;

    protected virtual Task ValidateAsync(TRequest request, int? id) => EnsureUniqueAsync(e => e.Name == request.Name.Trim() && e.Id != id);

    protected virtual string? DeleteBlockedReason(int id, int usageCount) =>
        usageCount > 0
            ? $"This {EntityName} is used by {usageCount.Counted(UsageNames.One, UsageNames.Many)} and cannot be deleted."
            : null;

    public async Task<PagedResult<TDto>> GetAllAsync(SortedQuery query)
    {
        var key = $"{CachePrefix}:{JsonSerializer.Serialize(query, query.GetType())}";
        return (await _cache.GetOrCreateAsync(key, entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = CacheLifetime;
            entry.AddExpirationToken(new CancellationChangeToken(_cache.GetOrCreate(ResetKey, _ => new CancellationTokenSource())!.Token));
            return LoadPageAsync(query);
        }))!;
    }

    public async Task<TDto> GetByIdAsync(int id)
    {
        var dto = await Entities().Where(e => e.Id == id).Select(Projection).FirstOrDefaultAsync()
            ?? throw new NotFoundException($"The {EntityName} was not found.");
        SetDeleteState(dto);
        return dto;
    }

    public async Task<TDto> CreateAsync(TRequest request)
    {
        await ValidateAsync(request, null);
        var entity = new TEntity();
        Apply(entity, request);
        Db.Set<TEntity>().Add(entity);
        await Db.SaveChangesAsync();
        ClearCache();
        _logger.LogInformation("Created {Entity} {Id}", EntityName, entity.Id);
        return await GetByIdAsync(entity.Id);
    }

    public async Task<TDto> UpdateAsync(int id, TRequest request)
    {
        var entity = await LoadAsync(id);
        await ValidateAsync(request, id);
        Apply(entity, request);
        await Db.SaveChangesAsync();
        ClearCache();
        return await GetByIdAsync(id);
    }

    public async Task DeleteAsync(int id)
    {
        var entity = await LoadAsync(id);
        var usage = await Entities().Where(e => e.Id == id).Select(Usage).FirstAsync();
        if (DeleteBlockedReason(id, usage) is { } reason)
            throw new ConflictException(reason);

        Db.Set<TEntity>().Remove(entity);
        await Db.SaveChangesAsync();
        ClearCache();
        _logger.LogInformation("Deleted {Entity} {Id}", EntityName, id);
    }

    protected async Task EnsureUniqueAsync(Expression<Func<TEntity, bool>> duplicate)
    {
        if (await Db.Set<TEntity>().AnyAsync(duplicate))
            throw new BusinessException($"A {EntityName} with this name already exists.", "name");
    }

    private IQueryable<TEntity> Entities() => Db.Set<TEntity>().AsNoTracking().IgnoreQueryFilters();

    private async Task<PagedResult<TDto>> LoadPageAsync(SortedQuery query)
    {
        var entities = Filter(Entities(), query);
        if (query.Search.Like() is { } like) entities = entities.Where(e => EF.Functions.Like(e.Name, like));

        var sorted = query.IsNewestFirst() ? entities.NewestFirst() : entities.OrderBy(e => e.Name);
        var page = await sorted.Select(Projection).ToPagedResultAsync(query);
        page.Items.ForEach(SetDeleteState);
        return page;
    }

    private void ClearCache()
    {
        if (_cache.Get<CancellationTokenSource>(ResetKey) is not { } reset) return;
        _cache.Remove(ResetKey);
        reset.Cancel();
    }

    private async Task<TEntity> LoadAsync(int id) =>
        await Db.Set<TEntity>().FirstOrDefaultAsync(e => e.Id == id)
        ?? throw new NotFoundException($"The {EntityName} was not found.");

    private void SetDeleteState(TDto dto)
    {
        dto.DeleteBlockedReason = DeleteBlockedReason(dto.Id, dto.UsageCount);
        dto.CanDelete = dto.DeleteBlockedReason == null;
    }
}
