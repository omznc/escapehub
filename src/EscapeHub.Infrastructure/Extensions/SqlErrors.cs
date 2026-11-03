using Microsoft.Data.SqlClient;

namespace EscapeHub.Infrastructure.Extensions;

public static class SqlErrors
{
    public const int ConstraintViolation = 547;
    public const int Deadlock = 1205;
    public const int UniqueIndexViolation = 2601;
    public const int UniqueConstraintViolation = 2627;

    public static bool HasSqlError(this Exception? exception, params int[] numbers) =>
        exception.FindSqlException() is { } sql && numbers.Contains(sql.Number);

    public static bool IsForeignKeyConflict(this Exception? exception) =>
        exception.FindSqlException() is { Number: ConstraintViolation } sql &&
        (sql.Message.Contains("FOREIGN KEY") || sql.Message.Contains("REFERENCE"));

    private static SqlException? FindSqlException(this Exception? exception)
    {
        for (; exception is not null; exception = exception.InnerException)
            if (exception is SqlException sql)
                return sql;
        return null;
    }
}
