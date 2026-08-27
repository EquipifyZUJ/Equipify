namespace Equipify.Service.Models;

/// <summary>Simple success/failure result carrying an optional error message.</summary>
public class ServiceResult
{
    public bool Success { get; init; }
    public string? Error { get; init; }

    public static ServiceResult Ok() => new() { Success = true };
    public static ServiceResult Fail(string error) => new() { Success = false, Error = error };
}

/// <summary>Result carrying a value on success.</summary>
public class ServiceResult<T> : ServiceResult
{
    public T? Value { get; init; }

    public static ServiceResult<T> Ok(T value) => new() { Success = true, Value = value };
    public static new ServiceResult<T> Fail(string error) => new() { Success = false, Error = error };
}
