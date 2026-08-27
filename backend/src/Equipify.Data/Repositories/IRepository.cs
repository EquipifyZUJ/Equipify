using System.Linq.Expressions;

namespace Equipify.Data.Repositories;

/// <summary>Generic repository abstraction over an EF Core entity set.</summary>
public interface IRepository<T> where T : class
{
    IQueryable<T> Query();
    Task<List<T>> GetAllAsync();
    Task<T?> GetByIdAsync(int id);
    Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate);
    Task<bool> AnyAsync(Expression<Func<T, bool>> predicate);
    Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null);
    Task AddAsync(T entity);
    void Update(T entity);
    void Remove(T entity);
}
