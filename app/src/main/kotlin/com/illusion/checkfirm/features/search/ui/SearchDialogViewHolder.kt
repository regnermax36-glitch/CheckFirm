package com.illusion.checkfirm.features.search.ui

import androidx.recyclerview.widget.RecyclerView
import com.illusion.checkfirm.data.model.local.DeviceItem
import com.illusion.checkfirm.databinding.RowMainSearchDialogFirmwareItemsBinding

class SearchDialogViewHolder(
    private val binding: RowMainSearchDialogFirmwareItemsBinding
) : RecyclerView.ViewHolder(binding.root) {

    fun bind(device: DeviceItem, item: String, onDownloadClick: (String, String, String) -> Unit) {
        binding.data.text = item
        binding.rowDownloadButton.setOnClickListener {
            onDownloadClick(device.model, device.csc, item)
        }
    }
}
