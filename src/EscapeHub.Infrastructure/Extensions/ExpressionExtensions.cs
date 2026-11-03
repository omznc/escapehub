using System.Linq.Expressions;

namespace EscapeHub.Infrastructure.Extensions;

public static class ExpressionExtensions
{
    public static Expression<Func<T, bool>> Not<T>(this Expression<Func<T, bool>> predicate) =>
        Expression.Lambda<Func<T, bool>>(Expression.Not(predicate.Body), predicate.Parameters);
}
