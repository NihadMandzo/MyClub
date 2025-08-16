using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class Club
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; }
        
        public string Description { get; set; }
        
        // Logo relationship
        public int? LogoImageId { get; set; }
        
        [ForeignKey("LogoImageId")]
        public virtual Asset LogoImage { get; set; }

        public DateTime EstablishedDate { get; set; }

        public string StadiumName { get; set; }
        public string StadiumLocation { get; set; }
        public int NumberOfTitles { get; set; }
        // Navigation collections
        public virtual ICollection<Player> Players { get; set; }
        public virtual ICollection<Match> Matches { get; set; }
    }
} 