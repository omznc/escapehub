namespace EscapeHub.Domain.Entities;

public class PromotionType : ReferenceEntity
{
    public bool IsPercentage { get; set; }

    public ICollection<Promotion> Promotions { get; set; } = new List<Promotion>();
}
