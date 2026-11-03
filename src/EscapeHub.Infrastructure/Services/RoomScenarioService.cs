using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.RoomScenarios;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Infrastructure.Services;

public class RoomScenarioService
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly ILogger<RoomScenarioService> _logger;

    public RoomScenarioService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, ILogger<RoomScenarioService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _logger = logger;
    }

    public Task<PagedResult<RoomScenarioDto>> GetAllAsync(RoomScenarioQuery query)
    {
        var scenarios = _db.RoomScenarios.AsNoTracking().Where(s => !s.IsDeleted);
        if (_currentUser.IsClient) scenarios = scenarios.Where(s => s.IsActive && s.Room.IsActive);
        else if (query.IsActive.HasValue) scenarios = scenarios.Where(s => s.IsActive == query.IsActive);
        if (_access.ManagerScope is { } managerId) scenarios = scenarios.Where(s => s.Room.ManagerId == managerId);
        if (query.RoomId.HasValue) scenarios = scenarios.Where(s => s.RoomId == query.RoomId);
        if (query.Search.Like() is { } like)
            scenarios = scenarios.Where(s => EF.Functions.Like(s.Name, like) || EF.Functions.Like(s.Room.Name, like));

        var sorted = query.IsNewestFirst() ? scenarios.NewestFirst() : scenarios.OrderBy(s => s.Room.Name).ThenBy(s => s.Name);
        return sorted.Select(ToDto).ToPagedResultAsync(query);
    }

    public async Task<RoomScenarioDto> GetByIdAsync(int id)
    {
        var scenario = await _db.RoomScenarios.AsNoTracking()
            .Where(s => s.Id == id && !s.IsDeleted && (!_currentUser.IsClient || (s.IsActive && s.Room.IsActive)))
            .Select(ToDto)
            .FirstOrDefaultAsync()
            ?? throw new NotFoundException("Scenario not found.");
        if (!_currentUser.IsClient) await _access.EnsureCanManageRoomAsync(scenario.RoomId);
        return scenario;
    }

    public async Task<RoomScenarioDto> CreateAsync(SaveRoomScenarioRequest request)
    {
        await ValidateAsync(request);
        var scenario = new RoomScenario();
        Apply(scenario, request);
        _db.RoomScenarios.Add(scenario);
        await _db.SaveChangesAsync();
        _logger.LogInformation("Scenario {ScenarioId} created for room {RoomId} by {UserId}", scenario.Id, scenario.RoomId, _currentUser.Id);
        return await GetByIdAsync(scenario.Id);
    }

    public async Task<RoomScenarioDto> UpdateAsync(int id, SaveRoomScenarioRequest request)
    {
        var scenario = await LoadAsync(id);
        await ValidateAsync(request);
        Apply(scenario, request);
        await _db.SaveChangesAsync();
        return await GetByIdAsync(id);
    }

    public async Task DeleteAsync(int id)
    {
        var scenario = await LoadAsync(id);
        scenario.IsDeleted = true;
        scenario.IsActive = false;
        await _db.SaveChangesAsync();
        _logger.LogInformation("Scenario {ScenarioId} deleted by {UserId}", id, _currentUser.Id);
    }

    private async Task<RoomScenario> LoadAsync(int id)
    {
        var scenario = await _db.RoomScenarios.Include(s => s.Room).FirstOrDefaultAsync(s => s.Id == id && !s.IsDeleted)
            ?? throw new NotFoundException("Scenario not found.");
        _access.EnsureCanManage(scenario.Room.ManagerId);
        return scenario;
    }

    private async Task ValidateAsync(SaveRoomScenarioRequest request)
    {
        await _access.EnsureCanManageRoomAsync(request.RoomId, "roomId");
        if (request.DifficultyOverrideId.HasValue && !await _db.DifficultyLevels.AnyAsync(d => d.Id == request.DifficultyOverrideId))
            throw new BusinessException("Select a difficulty level from the list.", "difficultyOverrideId");
    }

    private static void Apply(RoomScenario scenario, SaveRoomScenarioRequest request)
    {
        scenario.RoomId = request.RoomId;
        scenario.Name = request.Name.Trim();
        scenario.Story = request.Story.Trim();
        scenario.DifficultyOverrideId = request.DifficultyOverrideId;
        scenario.HintPolicy = string.IsNullOrWhiteSpace(request.HintPolicy) ? null : request.HintPolicy.Trim();
        scenario.IsActive = request.IsActive;
    }

    private static readonly Expression<Func<RoomScenario, RoomScenarioDto>> ToDto = s => new RoomScenarioDto
    {
        Id = s.Id,
        RoomId = s.RoomId,
        RoomName = s.Room.Name,
        RoomImageUrl = s.Room.ImageUrl,
        Name = s.Name,
        Story = s.Story,
        DifficultyOverrideId = s.DifficultyOverrideId,
        DifficultyName = s.DifficultyOverride != null ? s.DifficultyOverride.Name : s.Room.DifficultyLevel.Name,
        HintPolicy = s.HintPolicy,
        IsActive = s.IsActive
    };
}
