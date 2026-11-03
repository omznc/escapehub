using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Reference;
using EscapeHub.Domain.Constants;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Services.Reference;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Authorize]
public abstract class ReferenceDataController<TEntity, TDto, TRequest, TQuery> : ControllerBase
    where TEntity : ReferenceEntity, new()
    where TDto : ReferenceDto
    where TRequest : ReferenceRequest
    where TQuery : SortedQuery
{
    private readonly ReferenceService<TEntity, TDto, TRequest> _service;

    protected ReferenceDataController(ReferenceService<TEntity, TDto, TRequest> service) => _service = service;

    [HttpGet]
    public Task<PagedResult<TDto>> GetAll([FromQuery] TQuery query) => _service.GetAllAsync(query);

    [HttpGet("{id:int}")]
    public Task<TDto> Get(int id) => _service.GetByIdAsync(id);

    [HttpPost]
    [Authorize(Roles = Roles.Administrator)]
    public async Task<ActionResult<TDto>> Create(TRequest request)
    {
        var item = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id = item.Id }, item);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Administrator)]
    public Task<TDto> Update(int id, TRequest request) => _service.UpdateAsync(id, request);

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Administrator)]
    public async Task<IActionResult> Delete(int id)
    {
        await _service.DeleteAsync(id);
        return NoContent();
    }
}

[Route("api/themes")]
public class ThemesController : ReferenceDataController<Theme, ReferenceDto, ReferenceRequest, SortedQuery>
{
    public ThemesController(ThemeService service) : base(service) { }
}

[Route("api/difficulty-levels")]
public class DifficultyLevelsController : ReferenceDataController<DifficultyLevel, DifficultyLevelDto, DifficultyLevelRequest, SortedQuery>
{
    public DifficultyLevelsController(DifficultyLevelService service) : base(service) { }
}

[Route("api/booking-statuses")]
public class BookingStatusesController : ReferenceDataController<BookingStatus, ReferenceDto, ReferenceRequest, SortedQuery>
{
    public BookingStatusesController(BookingStatusService service) : base(service) { }
}

[Route("api/countries")]
public class CountriesController : ReferenceDataController<Country, ReferenceDto, ReferenceRequest, SortedQuery>
{
    public CountriesController(CountryService service) : base(service) { }
}

[Route("api/cities")]
public class CitiesController : ReferenceDataController<City, CityDto, CityRequest, CityQuery>
{
    public CitiesController(CityService service) : base(service) { }
}

[Route("api/promotion-types")]
public class PromotionTypesController : ReferenceDataController<PromotionType, DiscountTypeDto, DiscountTypeRequest, SortedQuery>
{
    public PromotionTypesController(PromotionTypeService service) : base(service) { }
}

[Route("api/reward-types")]
public class RewardTypesController : ReferenceDataController<RewardType, DiscountTypeDto, DiscountTypeRequest, SortedQuery>
{
    public RewardTypesController(RewardTypeService service) : base(service) { }
}
