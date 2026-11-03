namespace EscapeHub.Domain.Entities;

public class Country : ReferenceEntity
{
    public ICollection<City> Cities { get; set; } = new List<City>();
}
