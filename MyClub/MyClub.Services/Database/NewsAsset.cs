using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace MyClub.Services.Database
{
    public class NewsAsset
    {
        public int NewsId { get; set; }
        [ForeignKey("NewsId")]
        public virtual News News { get; set; }
        public int AssetId { get; set; }
        [ForeignKey("AssetId")]
        public virtual Asset Asset { get; set; }
    }

}