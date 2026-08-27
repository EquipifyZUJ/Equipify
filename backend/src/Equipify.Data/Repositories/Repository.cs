using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;

namespace Equipify.Data.Repositories;

/// <summary>EF Core implementation of <see cref="IRepository{T}"/>.</summary>
public class Repository<T> : IRepository<T> where T : class
{
    protected readonly EquipifyDbContext Context;
    protected readonly DbSet<T> Set;

    public Repository(EquipifyDbContext context)
    {
        Context = context;
        Set = context.Set<T>();
    }

    public IQueryable<T> Query() => Set.AsQueryable();

    public async Task<List<T>> GetAllAsync() => await Set.ToListAsync();

    public async Task<T?> GetByIdAsync(int id) => await Set.FindAsync(id);

    public async Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate)
        => await Set.FirstOrDefaultAsync(predicate);

    public async Task<bool> AnyAsync(Expression<Func<T, bool>> predicate)
        => await Set.AnyAsync(predicate);

    public async Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null)
        => predicate is null ? await Set.CountAsync() : await Set.CountAsync(predicate);

    public async Task AddAsync(T entity) => await Set.AddAsync(entity);

    public void Update(T entity) => Set.Update(entity);

    public void Remove(T entity) => Set.Remove(entity);
}
