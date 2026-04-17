package com.illusion.checkfirm.features.search.ui

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.illusion.checkfirm.data.model.local.DeviceItem
import com.illusion.checkfirm.databinding.RowMainSearchDialogFirmwareItemsBinding

class SearchDialogAdapter(
    private val device: DeviceItem,
    private val firmwareData: Array<String>,
    private val onDownloadClick: (String, String, String) -> Unit
) : RecyclerView.Adapter<SearchDialogViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): SearchDialogViewHolder {
        val binding = RowMainSearchDialogFirmwareItemsBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )

        return SearchDialogViewHolder(binding)
    }

    override fun onBindViewHolder(holder: SearchDialogViewHolder, position: Int) {
        holder.bind(device, firmwareData[position], onDownloadClick)
    }

    override fun getItemCount(): Int {
        return firmwareData.size
    }
}
