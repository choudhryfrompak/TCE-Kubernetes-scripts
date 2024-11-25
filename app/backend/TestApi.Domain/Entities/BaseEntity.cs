using System.ComponentModel.DataAnnotations;

namespace TestApi.Domain.Entities;

public class BaseEntity
{
    [Key]
    public int Id { get; set; }

}
